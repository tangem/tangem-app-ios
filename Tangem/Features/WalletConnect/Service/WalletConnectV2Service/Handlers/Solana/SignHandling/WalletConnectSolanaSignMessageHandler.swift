//
//  WalletConnectSolanaSignMessageHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import JSONRPC
import TangemLocalization
import Foundation
import Commons
import BlockchainSdk

struct WalletConnectSolanaSignMessageHandler {
    private let message: String
    private let signer: WalletConnectSigner
    private let walletModel: any WalletModel
    private let request: AnyCodable

    init(
        request: AnyCodable,
        signer: some WalletConnectSigner,
        blockchainId: String,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        let parameters = try request.get(WalletConnectSolanaSignMessageDTO.Response.self)

        do {
            guard
                let walletModel = wcAccountsWalletModelProvider.getModel(with: blockchainId, accountId: accountId)
            else {
                throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
            }

            let payload = parameters.message.base58DecodedData

            if walletModel.publicKey.isSharedAcrossBlockchains, !payload.isPlainTextMessage {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload("solana_signMessage payload must be a text message on a wallet whose key is shared across blockchains")
            }

            guard !SolanaTransactionHelper().isTransactionMessage(payload) else {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload("solana_signMessage payload is a serialized Solana transaction")
            }

            message = parameters.message
            self.walletModel = walletModel
        } catch let error as WalletConnectTransactionRequestProcessingError {
            WCLogger.error("Failed to create sign handler", error: error)
            throw error
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.error("Failed to create sign handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(stringRepresentation)
        }

        self.signer = signer
        self.request = request
    }
}

extension WalletConnectSolanaSignMessageHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .solanaSignMessage }

    var requestData: Data {
        message.data(using: .utf8) ?? Data()
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        do {
            let signature = try await signer.sign(data: message.base58DecodedData, using: walletModel)
            return .response(
                AnyCodable(WalletConnectSolanaSignMessageDTO.Body(signature: signature.base58EncodedString))
            )
        } catch {
            WCLogger.error("Failed to sign message", error: error)
            return .error(.internalError)
        }
    }
}

// MARK: - Shared key detection

private extension Wallet.PublicKey {
    var isSharedAcrossBlockchains: Bool {
        derivationType == nil
    }
}

// MARK: - Plain text message detection

private extension Data {
    var isPlainTextMessage: Bool {
        guard count != Constants.digestLength, let text = String(data: self, encoding: .utf8), !text.isEmpty else {
            return false
        }

        return text.unicodeScalars.allSatisfy { scalar in
            Constants.allowedControlCharacters.contains(scalar) || !CharacterSet.controlCharacters.contains(scalar)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let digestLength = 32
    static let allowedControlCharacters: Set<Unicode.Scalar> = ["\n", "\r", "\t"]
}
