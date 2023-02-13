//
//  WalletConnectV2HandlersService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain
import struct WalletConnectSwiftV2.Request
import enum WalletConnectSwiftV2.RPCResult

protocol WalletConnectV2HandlersServicing {
    func handle(
        _ request: Request,
        from dApp: WalletConnectSavedSession.DAppInfo,
        blockchain: Blockchain
    ) async throws -> RPCResult
}

struct WalletConnectV2HandlersService {
    private let uiDelegate: WalletConnectAlertUIDelegate
    private let handlersCreator: WalletConnectHandlersCreator

    private static let userRejectedResult = RPCResult.error(.init(code: 0, message: "User rejected sign"))

    init(
        uiDelegate: WalletConnectAlertUIDelegate,
        handlersCreator: WalletConnectHandlersCreator
    ) {
        self.uiDelegate = uiDelegate
        self.handlersCreator = handlersCreator
    }

    private func getHandler(for request: Request, blockchain: Blockchain) throws -> WalletConnectMessageHandler {
        let method = request.method
        guard let wcAction = WalletConnectAction(rawValue: method) else {
            throw WalletConnectV2Error.unsupportedWCMethod(method)
        }

        return try handlersCreator.createHandler(for: wcAction, with: request.params, blockchain: blockchain)
    }
}

extension WalletConnectV2HandlersService: WalletConnectV2HandlersServicing {
    func handle(
        _ request: Request,
        from dApp: WalletConnectSavedSession.DAppInfo,
        blockchain: Blockchain
    ) async throws -> RPCResult {
        let handler = try getHandler(for: request, blockchain: blockchain)

        let selectedAction = await uiDelegate.getResponseFromUser(with: WalletConnectAsyncUIRequest(
            event: handler.event,
            message: try await handler.messageForUser(from: dApp),
            approveAction: {
                AppLog.shared.debug("[WC 2.0] User approved sign request: \(request)")
                return try await handler.handle()
            },
            rejectAction: {
                AppLog.shared.debug("[WC 2.0] User rejected sign request: \(request)")
                return Self.userRejectedResult
            }
        ))

        return try await selectedAction()
    }
}
