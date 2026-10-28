//
//  WalletConnectSolanaSignMessageHandlerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Commons
import TangemSdk
import BlockchainSdk
@testable import Tangem

@Suite("Tests for `WalletConnectSolanaSignMessageHandler` payload validation")
struct WalletConnectSolanaSignMessageHandlerTests {
    @Test("Rejects a transaction message before signing", arguments: [
        Payload.legacyTransferMessage,
        Payload.versionedTransferMessage,
    ])
    func rejectsTransactionMessage(message: Data) throws {
        let publicKey = try makeDerivedPublicKey()

        let error = #expect(throws: WalletConnectTransactionRequestProcessingError.self) {
            _ = try makeHandler(message: message.base58EncodedString, signer: WalletConnectSignerSpy(), publicKey: publicKey)
        }

        guard case .invalidPayload? = error else {
            Issue.record("Expected invalidPayload, got \(String(describing: error))")
            return
        }
    }

    @Test("Rejects every message on a wallet whose key is shared across blockchains", arguments: [
        Payload.digest,
        Payload.algorandLikePayload,
        Payload.substrateLikePayload,
        Payload.signInText,
    ])
    func rejectsSharedKeyWallet(message: Data) {
        let signer = WalletConnectSignerSpy()

        let error = #expect(throws: WalletConnectTransactionRequestProcessingError.self) {
            _ = try makeHandler(message: message.base58EncodedString, signer: signer, publicKey: Payload.sharedPublicKey)
        }

        guard case .unsupportedMethod? = error else {
            Issue.record("Expected unsupportedMethod, got \(String(describing: error))")
            return
        }

        #expect(signer.signedData.isEmpty)
    }

    @Test("Signs a human-readable message as raw decoded bytes on a derived key")
    func signsHumanReadableMessage() async throws {
        let signer = WalletConnectSignerSpy()
        let publicKey = try makeDerivedPublicKey()

        let handler = try makeHandler(message: Payload.signInText.base58EncodedString, signer: signer, publicKey: publicKey)

        #expect(try await handler.validate() == .empty)
        _ = try await handler.handle()
        #expect(signer.signedData == [Payload.signInText])
    }
}

// MARK: - Helpers

private extension WalletConnectSolanaSignMessageHandlerTests {
    func makeHandler(message: String, signer: WalletConnectSignerSpy, publicKey: Wallet.PublicKey) throws -> WalletConnectSolanaSignMessageHandler {
        try WalletConnectSolanaSignMessageHandler(
            request: AnyCodable(WalletConnectSolanaSignMessageDTO.Response(message: message)),
            signer: signer,
            blockchainId: Payload.blockchain.networkId,
            wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProviderStub(
                walletModel: WalletModelTestsMock(
                    tokenItem: .blockchain(.init(Payload.blockchain, derivationPath: nil)),
                    isEmpty: false,
                    publicKey: publicKey
                )
            ),
            accountId: "account"
        )
    }

    func makeDerivedPublicKey() throws -> Wallet.PublicKey {
        let hdKey = Wallet.PublicKey.HDKey(
            path: try DerivationPath(rawPath: "m/44'/501'/0'/0'"),
            extendedPublicKey: ExtendedPublicKey(publicKey: Payload.victimKey, chainCode: Data(repeating: 0x00, count: 32))
        )

        return Wallet.PublicKey(seedKey: Payload.victimKey, derivationType: .plain(hdKey))
    }
}

// MARK: - Stubs

private enum Payload {
    static let blockchain = Blockchain.solana(curve: .ed25519, testnet: false)

    static let victimKey = Data(repeating: 0xA0, count: 32)
    static let attackerKey = Data(repeating: 0xB1, count: 32)
    static let systemProgramKey = Data(repeating: 0x00, count: 32)
    static let blockhash = Data(repeating: 0xD3, count: 32)
    static let transferInstructionData = Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x65, 0xCD, 0x1D, 0x00, 0x00, 0x00, 0x00])

    static let sharedPublicKey = Wallet.PublicKey(seedKey: victimKey, derivationType: nil)

    static let signInText = Data("example.com wants you to sign in with your Solana account".utf8)

    static let digest = Data(repeating: 0x5C, count: 32)

    static let algorandLikePayload: Data = {
        var data = Data("TX".utf8)
        data.append(contentsOf: [0x83, 0xA3, 0x61, 0x6D, 0x74, 0xCE, 0x00, 0x6A, 0xCF, 0xC0])
        data.append(contentsOf: [0xA3, 0x73, 0x6E, 0x64, 0xC4, 0x20])
        data.append(victimKey)
        data.append(contentsOf: [0xA4, 0x74, 0x79, 0x70, 0x65, 0xA3, 0x70, 0x61, 0x79])
        return data
    }()

    static let substrateLikePayload: Data = {
        var data = Data([0x0A, 0x00])
        data.append(attackerKey)
        data.append(contentsOf: [0x03, 0x00, 0x94, 0x35, 0x77, 0xA5, 0x03, 0x0C, 0x00, 0x00, 0x1A, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00])
        data.append(blockhash)
        data.append(blockhash)
        return data
    }()

    static let legacyTransferMessage: Data = {
        var data = Data([0x01, 0x00, 0x01, 0x03])
        data.append(victimKey)
        data.append(attackerKey)
        data.append(systemProgramKey)
        data.append(blockhash)
        data.append(contentsOf: [0x01, 0x02, 0x02, 0x00, 0x01])
        data.append(UInt8(transferInstructionData.count))
        data.append(transferInstructionData)
        return data
    }()

    static let versionedTransferMessage: Data = {
        var data = Data([0x80, 0x01, 0x00, 0x01, 0x02])
        data.append(victimKey)
        data.append(systemProgramKey)
        data.append(blockhash)
        data.append(contentsOf: [0x01, 0x01, 0x02, 0x00, 0x02])
        data.append(UInt8(transferInstructionData.count))
        data.append(transferInstructionData)
        data.append(0x01)
        data.append(Data(repeating: 0xE4, count: 32))
        data.append(contentsOf: [0x01, 0x00, 0x00])
        return data
    }()
}
