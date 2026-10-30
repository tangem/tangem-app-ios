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
        parameters: PredefinedSwapParameters,
        analyticsLogger: any SendAnalyticsLogger,
        autoupdatingTimer: AutoupdatingTimer,
        pairUpdateHandler: SwapPairUpdateHandler,
        initialResolvingPolicy: SwapModel.InitialResolvingPolicy
    ) -> SwapModel {
        SwapModel(
            parameters: parameters,
            expressManager: expressDependenciesFactory.expressManager,
            swapRepository: expressDependenciesFactory.swapRepository,
            expressPendingTransactionRepository: expressDependenciesFactory.expressPendingTransactionRepository,
            expressAPIProvider: expressDependenciesFactory.expressAPIProvider,
            expressUserWalletId: expressDependenciesFactory.userWalletInfo.id,
            analyticsLogger: analyticsLogger,
            autoupdatingTimer: autoupdatingTimer,
            pairUpdateHandler: pairUpdateHandler,
            balanceRestrictionFeatureChecker: makeSwapBalanceRestrictionFeatureChecker(),
            initialResolvingPolicy: initialResolvingPolicy,
        )
    }

    func makeSwapNotificationManager() -> SwapNotificationManager {
        CommonSwapNotificationManager()
    }

    func makeSwapMarketingBannerManager() -> SwapMarketingBannerManager {
        SwapMarketingBannerManager()
    }

    func makeSwapAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    func makeSwapBalanceRestrictionFeatureChecker() -> SwapBalanceRestrictionFeatureChecker {
        CommonSwapBalanceRestrictionFeatureChecker()
    }
}
