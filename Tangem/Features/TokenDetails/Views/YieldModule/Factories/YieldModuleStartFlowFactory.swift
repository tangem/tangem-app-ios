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
    private weak var coordinator: YieldModulePromoCoordinator?

    // MARK: - Init

    init(walletModel: any WalletModel, yieldManagerInteractor: YieldManagerInteractor, coordinator: YieldModulePromoCoordinator?) {
        self.walletModel = walletModel
        self.yieldManagerInteractor = yieldManagerInteractor
        self.coordinator = coordinator
    }

    // MARK: - Public Implementation

    func makeStartViewModel() -> YieldModuleStartViewModel {
        YieldModuleStartViewModel(
            walletModel: walletModel,
            viewState: .startEarning,
            coordinator: coordinator,
            yieldManagerInteractor: yieldManagerInteractor
        )
    }

    func makeInterestRateInfoVewModel() -> YieldModuleStartViewModel {
        YieldModuleStartViewModel(
            walletModel: walletModel,
            viewState: .rateInfo,
            coordinator: nil,
            yieldManagerInteractor: yieldManagerInteractor
        )
    }
}
