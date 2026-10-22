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
    func rejectsTransactionMessage(message: Data) {
        let error = #expect(throws: WalletConnectTransactionRequestProcessingError.self) {
            _ = try makeHandler(message: message.base58EncodedString, signer: WalletConnectSignerSpy())
        }

        guard case .invalidPayload? = error else {
            Issue.record("Expected invalidPayload, got \(String(describing: error))")
            return
        }
    }

    @Test("Signs a human-readable message as raw decoded bytes")
    func signsHumanReadableMessage() async throws {
        let signer = WalletConnectSignerSpy()
        let text = Data("example.com wants you to sign in with your Solana account".utf8)

        let handler = try makeHandler(message: text.base58EncodedString, signer: signer)

        #expect(try await handler.validate() == .empty)
        _ = try await handler.handle()
        #expect(signer.signedData == [text])
    }

    private func makeHandler(message: String, signer: WalletConnectSignerSpy) throws -> WalletConnectSolanaSignMessageHandler {
        try WalletConnectSolanaSignMessageHandler(
            request: AnyCodable(WalletConnectSolanaSignMessageDTO.Response(message: message)),
            signer: signer,
            blockchainId: Payload.blockchain.networkId,
            wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProviderStub(
                walletModel: WalletModelTestsMock(
                    tokenItem: .blockchain(.init(Payload.blockchain, derivationPath: nil)),
                    isEmpty: false
                )
            ),
            accountId: "account"
        )
    }
}

private enum Payload {
    static let blockchain = Blockchain.solana(curve: .ed25519, testnet: false)

    static let victimKey = Data(repeating: 0xA0, count: 32)
    static let attackerKey = Data(repeating: 0xB1, count: 32)
    static let systemProgramKey = Data(repeating: 0x00, count: 32)
    static let blockhash = Data(repeating: 0xD3, count: 32)
    static let transferInstructionData = Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x65, 0xCD, 0x1D, 0x00, 0x00, 0x00, 0x00])

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
