//
//  MCPIntentDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemLogger.Logger

final class MCPIntentDeeplinkResponder: IncomingActionResponder {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    private lazy var swapIntentHandler = SwapMCPIntentHandler()
    private lazy var sendIntentHandler = SendMCPIntentHandler()
    private let logger: TangemLogger.Logger = MCPLogger

    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard
            FeatureProvider.isAvailable(.mcp),
            case .navigation(.mcpIntent(let intentDeeplink)) = action,
            userWalletRepository.selectedModel != nil
        else {
            return false
        }

        logger.debug("Received MCP intent deeplink \(intentDeeplink.debugDescription)")

        switch (intentDeeplink.source, intentDeeplink.type) {
        case ("express", "exchange"):
            MCPIntentAnalyticsReporter(intentType: .exchange)
                .reportIntentReceived(intentID: intentDeeplink.id, source: intentDeeplink.source)

            Task { @MainActor in
                await swapIntentHandler.handle(intentDeeplink)
            }
            return true

        case ("transaction", "send"):
            guard SendFeatureProvider.shared.isAvailable else {
                logger.warning("Send feature is unavailable. Send MCP intent with id \(intentDeeplink.id) will not be handled.")
                return false
            }
            MCPIntentAnalyticsReporter(intentType: .send)
                .reportIntentReceived(intentID: intentDeeplink.id, source: intentDeeplink.source)

            Task { @MainActor in
                await sendIntentHandler.handle(intentDeeplink)
            }
            return true

        default:
            logger.warning("Unrecognized intent deeplink. Handling finished")
            return false
        }
    }
}
