//
//  YieldModuleTransactionFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class YieldModuleTransactionFlowFactory {
    private let walletModel: any WalletModel
    private let yieldManagerInteractor: YieldManagerInteractor
    private let logger: YieldAnalyticsLogger
    private weak var coordinator: YieldModuleActiveCoordinator?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldManagerInteractor: YieldManagerInteractor,
        logger: YieldAnalyticsLogger,
        coordinator: YieldModuleActiveCoordinator? = nil
    ) {
        self.walletModel = walletModel
        self.yieldManagerInteractor = yieldManagerInteractor
        self.logger = logger
        self.coordinator = coordinator
    }

    // MARK: - Public Implementation

    func makeTransactionViewModel(action: YieldModuleAction) -> YieldModuleTransactionViewModel {
        YieldModuleTransactionViewModel(
            action: action,
            walletModel: walletModel,
            coordinator: coordinator,
            yieldManagerInteractor: yieldManagerInteractor,
            notificationManager: YieldModuleNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem),
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )
    }
}
