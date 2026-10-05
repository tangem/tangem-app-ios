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
    private let claimInteractor: YieldIncentivesClaimInteractor?
    private let logger: YieldAnalyticsLogger
    private let tangemIconProvider: TangemIconProvider
    private let confirmTransactionPolicy: ConfirmTransactionPolicy
    private weak var coordinator: YieldModuleActiveCoordinator?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldManagerInteractor: YieldManagerInteractor,
        claimInteractor: YieldIncentivesClaimInteractor?,
        logger: YieldAnalyticsLogger,
        tangemIconProvider: TangemIconProvider,
        confirmTransactionPolicy: ConfirmTransactionPolicy,
        coordinator: YieldModuleActiveCoordinator? = nil
    ) {
        self.walletModel = walletModel
        self.yieldManagerInteractor = yieldManagerInteractor
        self.claimInteractor = claimInteractor
        self.logger = logger
        self.tangemIconProvider = tangemIconProvider
        self.confirmTransactionPolicy = confirmTransactionPolicy
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
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId),
            tangemIconProvider: tangemIconProvider,
            confirmTransactionPolicy: confirmTransactionPolicy
        )
    }

    func makeClaimViewModel(summary: YieldIncentivesRewardsSummary) -> YieldModuleClaimViewModel? {
        guard let claimInteractor else {
            return nil
        }

        return YieldModuleClaimViewModel(
            summary: summary,
            walletModel: walletModel,
            coordinator: coordinator,
            claimInteractor: claimInteractor,
            notificationManager: YieldModuleNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem),
            tangemIconProvider: tangemIconProvider,
            confirmTransactionPolicy: confirmTransactionPolicy
        )
    }
}
