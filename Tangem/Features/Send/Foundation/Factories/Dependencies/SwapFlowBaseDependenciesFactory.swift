//
//  SwapFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SwapFlowBaseDependenciesFactory: SendGenericFlowBaseDependenciesFactory {
    var expressDependenciesFactory: ExpressDependenciesFactory { get }
}

// MARK: - Shared dependencies

extension SwapFlowBaseDependenciesFactory {
    // MARK: - Management Model

    func makeSwapModel(
        sourceToken: SendSwapableToken?,
        receiveToken: SendReceiveToken?,
        analyticsLogger: any SendAnalyticsLogger,
        autoupdatingTimer: AutoupdatingTimer,
        shouldStartInitialLoading: Bool,
        isReceiveTokenSelectionAvailable: Bool = true,
        isFixedRatesEnabled: Bool = false
    ) -> SwapModel {
        SwapModel(
            sourceToken: sourceToken,
            receiveToken: receiveToken,
            expressManager: expressDependenciesFactory.expressManager,
            expressPairsRepository: expressDependenciesFactory.expressPairsRepository,
            expressPendingTransactionRepository: expressDependenciesFactory.expressPendingTransactionRepository,
            expressDestinationService: expressDependenciesFactory.expressDestinationService,
            expressAPIProvider: expressDependenciesFactory.expressAPIProvider,
            analyticsLogger: analyticsLogger,
            autoupdatingTimer: autoupdatingTimer,
            shouldStartInitialLoading: shouldStartInitialLoading,
            isReceiveTokenSelectionAvailable: isReceiveTokenSelectionAvailable,
            isFixedRatesEnabled: isFixedRatesEnabled
        )
    }

    func makeSwapNotificationManager() -> SwapNotificationManager {
        CommonSwapNotificationManager()
    }

    func makeSwapAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    func makeSwapTransactionSummaryDescriptionBuilder() -> SwapTransactionSummaryDescriptionBuilder {
        CommonSwapTransactionSummaryDescriptionBuilder()
    }
}
