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

struct WalletConnectSolanaSignMessageHandler {
    private let message: String
    private let signer: WalletConnectSigner
    private let walletModel: any WalletModel
    private let request: AnyCodable

    init(
        request: AnyCodable,
        signer: some WalletConnectSigner,
        blockchainId: String,
        walletModelProvider: some WalletConnectWalletModelProvider
    ) throws {
        let parameters = try request.get(WalletConnectSolanaSignMessageDTO.Response.self)

        do {
            guard let walletModel = walletModelProvider.getModel(with: blockchainId) else {
                throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainId)
            }

            message = parameters.message
            self.walletModel = walletModel
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.error("Failed to create sign handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.dataInWrongFormat(stringRepresentation)
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
