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
        pairUpdateHandler: SwapPairUpdateHandler,
        shouldStartInitialLoading: Bool,
        swapTokenPairResolver: MainSwapPairResolver? = nil
    ) -> SwapModel {
        SwapModel(
            sourceToken: sourceToken,
            receiveToken: receiveToken,
            expressManager: expressDependenciesFactory.expressManager,
            swapRepository: expressDependenciesFactory.swapRepository,
            expressPendingTransactionRepository: expressDependenciesFactory.expressPendingTransactionRepository,
            expressAPIProvider: expressDependenciesFactory.expressAPIProvider,
            expressUserWalletId: expressDependenciesFactory.userWalletInfo.id,
            analyticsLogger: analyticsLogger,
            autoupdatingTimer: autoupdatingTimer,
            pairUpdateHandler: pairUpdateHandler,
            balanceRestrictionFeatureChecker: makeSwapBalanceRestrictionFeatureChecker(),
            swapTokenPairResolver: swapTokenPairResolver,
            shouldStartInitialLoading: shouldStartInitialLoading,
        )
    }

    func makeSwapNotificationManager() -> SwapNotificationManager {
        CommonSwapNotificationManager()
    }

    func makeSwapMarketingBannerNotificationManager() -> SwapMarketingBannerNotificationManager {
        SwapMarketingBannerNotificationManager()
    }

    func makeSwapAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    func makeSwapBalanceRestrictionFeatureChecker() -> SwapBalanceRestrictionFeatureChecker {
        CommonSwapBalanceRestrictionFeatureChecker()
    }
}
