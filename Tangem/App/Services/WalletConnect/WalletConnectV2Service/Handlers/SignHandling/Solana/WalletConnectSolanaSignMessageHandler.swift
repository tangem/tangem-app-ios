//
//  WalletConnectSolanaSignMessageHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import JSONRPC
import Foundation
import Commons

struct WalletConnectSolanaSignMessageHandler {
    private let message: String
    private let signer: WalletConnectSigner
    private let walletModel: WalletModel

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
            AppLog.shared.debug("[WC 2.0] Failed to create sign handler. Raised error: \(error)")
            throw WalletConnectV2Error.dataInWrongFormat(stringRepresentation)
        }

        self.signer = signer
    }
}

extension WalletConnectSolanaSignMessageHandler: WalletConnectMessageHandler {
    var event: WalletConnectEvent {
        .sign
    }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        let message = Localization.walletConnectPersonalSignMessage(dApp.name, message)
        return Localization.walletConnectAlertSignMessage(message)
    }

    func handle() async throws -> RPCResult {
        do {
            let signature = try await signer.sign(data: message.base58DecodedData, using: walletModel)
            return .response(
                AnyCodable(WalletConnectSolanaSignMessageDTO.Body(signature: signature))
            )
        } catch {
            AppLog.shared.debug("[WC 2.0] Failed to sign message. \(error)")
            return .error(.internalError)
        }
    }
}
