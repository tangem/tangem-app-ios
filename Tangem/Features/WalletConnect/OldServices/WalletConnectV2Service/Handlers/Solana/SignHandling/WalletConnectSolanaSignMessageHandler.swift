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

    init(
        request: AnyCodable,
        signer: some WalletConnectSigner,
        blockchainId: String,
        walletModelProvider: some WalletConnectWalletModelProvider
    ) throws {
        let parameters = try request.get(WalletConnectSolanaSignMessageDTO.Response.self)

        do {
            guard let walletModel = walletModelProvider.getModel(with: blockchainId) else {
                throw WalletConnectV2Error.walletModelNotFound(blockchainId)
            }

            message = parameters.message
            self.walletModel = walletModel
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.error("Failed to create sign handler", error: error)
            throw WalletConnectV2Error.dataInWrongFormat(stringRepresentation)
        }

        self.signer = signer
    }
}

extension WalletConnectSolanaSignMessageHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .solanaSignMessage }

    var requestData: Data {
        message.data(using: .utf8) ?? Data()
    }

    var event: WalletConnectEvent { .sign }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        let message = Localization.walletConnectPersonalSignMessage(dApp.name, message)
        return Localization.walletConnectAlertSignMessage(message)
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
