//
//  YieldModuleStartFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class YieldStartFlowFactory {
    private let walletModel: any WalletModel
    private let yieldManagerInteractor: YieldManagerInteractor
    private let logger: YieldAnalyticsLogger
    private weak var coordinator: YieldModulePromoCoordinator?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldManagerInteractor: YieldManagerInteractor,
        coordinator: YieldModulePromoCoordinator?,
        logger: YieldAnalyticsLogger
    ) {
        self.walletModel = walletModel
        self.yieldManagerInteractor = yieldManagerInteractor
        self.coordinator = coordinator
        self.logger = logger
    }

    // MARK: - Public Implementation

    func makeStartViewModel() -> YieldModuleStartViewModel {
        YieldModuleStartViewModel(
            walletModel: walletModel,
            viewState: .startEarning,
            coordinator: coordinator,
            yieldManagerInteractor: yieldManagerInteractor,
            logger: logger
        )
    }

    func makeInterestRateInfoVewModel() -> YieldModuleStartViewModel {
        YieldModuleStartViewModel(
            walletModel: walletModel,
            viewState: .rateInfo,
            coordinator: nil,
            yieldManagerInteractor: yieldManagerInteractor,
            logger: logger
        )
    }
}
