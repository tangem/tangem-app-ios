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
    private let tangemIconProvider: TangemIconProvider
    private weak var coordinator: YieldModulePromoCoordinator?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldManagerInteractor: YieldManagerInteractor,
        coordinator: YieldModulePromoCoordinator?,
        logger: YieldAnalyticsLogger,
        tangemIconProvider: TangemIconProvider
    ) {
        self.walletModel = walletModel
        self.yieldManagerInteractor = yieldManagerInteractor
        self.coordinator = coordinator
        self.logger = logger
        self.tangemIconProvider = tangemIconProvider
    }

    // MARK: - Public Implementation

    func makeStartViewModel() -> YieldModuleStartViewModel {
        YieldModuleStartViewModel(
            walletModel: walletModel,
            viewState: .startEarning,
            coordinator: coordinator,
            yieldManagerInteractor: yieldManagerInteractor,
            logger: logger,
            tangemIconProvider: tangemIconProvider
        )
    }

    func makeInterestRateInfoVewModel() -> YieldModuleStartViewModel {
        YieldModuleStartViewModel(
            walletModel: walletModel,
            viewState: .rateInfo,
            coordinator: nil,
            yieldManagerInteractor: yieldManagerInteractor,
            logger: logger,
            tangemIconProvider: tangemIconProvider
        )
    }
}
