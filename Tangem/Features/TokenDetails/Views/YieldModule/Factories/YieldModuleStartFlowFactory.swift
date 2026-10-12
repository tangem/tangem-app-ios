//
//  YieldModuleStartFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class YieldStartFlowFactory {
    private let walletModel: any WalletModel
    private let yieldManagerInteractor: YieldManagerInteractor
    private let logger: YieldAnalyticsLogger
    private let tangemIconProvider: TangemIconProvider
    private let confirmTransactionPolicy: ConfirmTransactionPolicy
    private weak var coordinator: YieldModulePromoCoordinator?

    private var marketIncentive: YieldModuleMarketIncentive? {
        guard FeatureProvider.isAvailable(.merklIncentives) else { return nil }

        return walletModel.yieldModuleManager?.state?.marketInfo?.incentive
    }

    private var currentApy: Decimal? {
        walletModel.yieldModuleManager?.state?.marketInfo?.effectiveApy
    }

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldManagerInteractor: YieldManagerInteractor,
        coordinator: YieldModulePromoCoordinator?,
        logger: YieldAnalyticsLogger,
        tangemIconProvider: TangemIconProvider,
        confirmTransactionPolicy: ConfirmTransactionPolicy
    ) {
        self.walletModel = walletModel
        self.yieldManagerInteractor = yieldManagerInteractor
        self.coordinator = coordinator
        self.logger = logger
        self.tangemIconProvider = tangemIconProvider
        self.confirmTransactionPolicy = confirmTransactionPolicy
    }

    // MARK: - Public Implementation

    func makeStartViewModel() -> YieldModuleStartViewModel {
        makeViewModel(viewState: .startEarning, coordinator: coordinator)
    }

    func makeInterestRateInfoVewModel() -> YieldModuleStartViewModel {
        makeViewModel(viewState: .rateInfo, coordinator: nil)
    }

    func makeIncentiveRateInfoViewModel() -> YieldModuleStartViewModel {
        makeViewModel(viewState: .incentiveRateInfo, coordinator: nil)
    }

    // MARK: - Private Implementation

    private func makeViewModel(
        viewState: YieldModuleStartViewModel.ViewState,
        coordinator: YieldModulePromoCoordinator?
    ) -> YieldModuleStartViewModel {
        YieldModuleStartViewModel(
            walletModel: walletModel,
            viewState: viewState,
            marketIncentive: marketIncentive,
            currentApy: currentApy,
            coordinator: coordinator,
            yieldManagerInteractor: yieldManagerInteractor,
            logger: logger,
            tangemIconProvider: tangemIconProvider,
            confirmTransactionPolicy: confirmTransactionPolicy
        )
    }
}
