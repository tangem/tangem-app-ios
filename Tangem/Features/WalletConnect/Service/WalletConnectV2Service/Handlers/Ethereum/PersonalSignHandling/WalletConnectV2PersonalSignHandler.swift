//
//  WalletConnectV2PersonalSignHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import CryptoSwift
import enum BlockchainSdk.Blockchain
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

struct WalletConnectV2PersonalSignHandler {
    private let message: String
    private let signer: WalletConnectSigner
    private let walletModel: any WalletModel
    private let request: AnyCodable

    /// The bytes that go under the `\u{19}Ethereum Signed Message:\n` prefix.
    ///
    /// Follows the `personal_sign` convention every other wallet (MetaMask / eth-sig-util `legacyToBuffer`)
    /// implements: only a `0x`-prefixed hex string is raw bytes; anything else — including hex-looking
    /// plain text such as `"deadbeef"` — is signed as UTF-8. The previous heuristic decoded any hex-parsable
    /// text as bytes, so the signature Tangem produced for such a message did not verify on the dApp side.
    private var dataToSign: Data {
        guard message.hasHexPrefix() else {
            return Data(message.utf8)
        }

        let body = message.removeHexPrefix()
        guard body.allSatisfy({ $0.isASCII && $0.isHexDigit }) else {
            return Data(message.utf8)
        }

        // `toBuffer` left-pads an odd-length hex string with a zero nibble.
        let evenBody = body.count.isMultiple(of: 2) ? body : "0" + body
        return Data(hex: evenBody)
    }

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        let castedParams: [String]
        do {
            castedParams = try request.get([String].self)

            if castedParams.count < 2 {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload(request.description)
            }

            let targetAddress = castedParams[1]

            walletModel = try wcAccountsWalletModelProvider.getModel(
                with: targetAddress,
                blockchainId: blockchainId,
                accountId: accountId
            )

            self.request = request
        } catch let error as WalletConnectTransactionRequestProcessingError {
            WCLogger.error("Failed to create sign handler", error: error)
            throw error
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.error("Failed to create sign handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(stringRepresentation)
        }

        message = castedParams[0]
        self.signer = signer
    }

    private func makePersonalMessageData(_ data: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + "\(data.count)").data(using: .utf8)!
        return prefixData + data
    }
}

extension WalletConnectV2PersonalSignHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .personalSign }

    var requestData: Data {
        // Expose exactly the bytes that are signed, so the "Contents" row and the Blockaid scan see the
        // message text instead of an empty buffer for a plain-text message.
        dataToSign
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        let personalMessageData = makePersonalMessageData(dataToSign)
        let hash = personalMessageData.sha3(.keccak256)

        do {
            let signedMessage = try await signer.sign(data: hash, using: walletModel)
            return .response(AnyCodable(signedMessage.hexString.addHexPrefix().lowercased()))
        } catch {
            WCLogger.error("Failed to sign message", error: error)
            throw error
        }
    }
}
