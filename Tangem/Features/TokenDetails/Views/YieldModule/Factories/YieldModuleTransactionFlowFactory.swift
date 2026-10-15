//
//  YieldModuleTransactionFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

final class YieldModuleTransactionFlowFactory {
    private let walletModel: any WalletModel
    private let yieldManagerInteractor: YieldManagerInteractor
    private let claimInteractor: YieldIncentivesClaimInteractor?
    private let logger: YieldAnalyticsLogger
    private let signingActionButtonType: SigningActionButtonViewType
    private weak var coordinator: YieldModuleActiveCoordinator?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldManagerInteractor: YieldManagerInteractor,
        claimInteractor: YieldIncentivesClaimInteractor?,
        logger: YieldAnalyticsLogger,
        signingActionButtonType: SigningActionButtonViewType,
        coordinator: YieldModuleActiveCoordinator? = nil
    ) {
        self.walletModel = walletModel
        self.yieldManagerInteractor = yieldManagerInteractor
        self.claimInteractor = claimInteractor
        self.logger = logger
        self.signingActionButtonType = signingActionButtonType
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
            signingActionButtonType: signingActionButtonType
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
            signingActionButtonType: signingActionButtonType
        )
    }
}
