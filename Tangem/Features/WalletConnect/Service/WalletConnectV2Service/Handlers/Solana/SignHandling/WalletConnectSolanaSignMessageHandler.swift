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
        let messageData = message.base58DecodedData

        // Blind-signing guard: refuse to raw-sign bytes that deserialize as a Solana transaction
        // message (legacy or v0). A signature over a transaction message is a valid transaction
        // signature, so a dApp could otherwise obtain a transaction signature disguised as an
        // off-chain `solana_signMessage` (which the user only sees as a base58 blob and which gets
        // no per-transaction simulation). Genuine off-chain messages are unaffected.
        if SolanaTransactionHelper().looksLikeTransactionMessage(messageData) {
            WCLogger.error("Rejected solana_signMessage: payload deserializes as a Solana transaction message (blind-signing attempt)")
            return .error(.init(
                code: -32602,
                message: "Refusing to raw-sign a Solana transaction message via solana_signMessage"
            ))
        }

        do {
            let signature = try await signer.sign(data: messageData, using: walletModel)
            return .response(
                AnyCodable(WalletConnectSolanaSignMessageDTO.Body(signature: signature.base58EncodedString))
            )
        } catch {
            WCLogger.error("Failed to sign message", error: error)
            return .error(.internalError)
        }
    }
}
