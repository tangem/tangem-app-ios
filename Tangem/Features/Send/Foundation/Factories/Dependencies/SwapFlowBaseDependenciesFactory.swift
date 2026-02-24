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
        sourceToken: SendSourceToken,
        analyticsLogger: any SendAnalyticsLogger,
        autoupdatingTimer: AutoupdatingTimer
    ) -> SwapModel {
        SwapModel(
            sourceToken: sourceToken,
            receiveToken: .none,
            expressManager: expressDependenciesFactory.expressManager,
            expressPairsRepository: expressDependenciesFactory.expressPairsRepository,
            expressPendingTransactionRepository: expressDependenciesFactory.expressPendingTransactionRepository,
            expressDestinationService: expressDependenciesFactory.expressDestinationService,
            expressAPIProvider: expressDependenciesFactory.expressAPIProvider,
            analyticsLogger: analyticsLogger,
            autoupdatingTimer: autoupdatingTimer
        )
    }

    func makeSwapNotificationManager() -> SwapNotificationManager {
        CommonSwapNotificationManager()
    }

    func makeSendAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }
}
