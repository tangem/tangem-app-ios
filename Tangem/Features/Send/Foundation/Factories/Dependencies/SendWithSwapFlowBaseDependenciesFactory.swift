//
//  SendWithSwapFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendWithSwapFlowBaseDependenciesFactory: SendFlowBaseDependenciesFactory, SwapFlowBaseDependenciesFactory {}

// MARK: - Shared dependencies

extension SendWithSwapFlowBaseDependenciesFactory {
    func makeSendWithSwapModel(
        transferModel: TransferModel,
        swapModel: SwapModel,
        analyticsLogger: any SendAnalyticsLogger,
        predefinedValues: TransferModel.PredefinedValues,
        autoupdatingTimer: AutoupdatingTimer,
    ) -> SendWithSwapModel {
        return SendWithSwapModel(
            transferModel: transferModel,
            swapModel: swapModel,
            initialSourceToken: transferableToken,
            receiveTokenBuilder: makeSendReceiveTokenBuilder(),
            sendAlertBuilder: makeSendAlertBuilder(),
            analyticsLogger: analyticsLogger
        )
    }

    // MARK: - Receive token

    func makeSendReceiveTokenBuilder() -> SendReceiveTokenBuilder {
        SendReceiveTokenBuilder(tokenIconInfoBuilder: TokenIconInfoBuilder(), fiatItem: transferableToken.fiatItem)
    }

    // MARK: - Notifications

    func makeSendWithSwapNotificationManager(
        receiveTokenInput: SendReceiveTokenInput,
        sendNotificationManager: SendNotificationManager,
        swapNotificationManager: SwapNotificationManager
    ) -> NotificationManager {
        SendWithSwapNotificationManager(
            receiveTokenInput: receiveTokenInput,
            sendNotificationManager: sendNotificationManager,
            swapNotificationManager: swapNotificationManager
        )
    }
}
