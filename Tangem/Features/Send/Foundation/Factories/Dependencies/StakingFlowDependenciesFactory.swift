//
//   StakingFlowDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemLocalization

/// Sharing between Staking / Restaking / Unstaking / StakingSingleAction
protocol StakingFlowDependenciesFactory: SendGenericFlowBaseDependenciesFactory {
    var actionType: StakingAction.ActionType { get }
}

// MARK: - Shared dependencies

extension StakingFlowDependenciesFactory {
    func makeStakingNotificationManager(analyticsLogger: StakingSendAnalyticsLogger) -> StakingNotificationManager {
        CommonStakingNotificationManager(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            analyticsLogger: analyticsLogger
        )
    }

    func makeStakingAlertBuilder() -> SendAlertBuilder {
        StakingSendAlertBuilder()
    }

    func makeStakingBaseDataBuilder(input: StakingBaseDataBuilderInput) -> StakingBaseDataBuilder {
        baseDataBuilderFactory.makeStakingBaseDataBuilder(input: input)
    }

    func makeStakingFeeIncludedCalculator() -> FeeIncludedCalculator {
        StakingFeeIncludedCalculator(tokenItem: tokenItem, validator: walletModelDependenciesProvider.transactionValidator)
    }

    func makeStakingTransactionSummaryDescriptionBuilder() -> StakingTransactionSummaryDescriptionBuilder {
        CommonStakingTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
    }

    func makeStakingSendAnalyticsLogger() -> StakingSendAnalyticsLogger {
        CommonStakingSendAnalyticsLogger(
            tokenItem: tokenItem,
            actionType: actionType.sendFlowActionType
        )
    }

    func makeStakingSummaryTitleProvider() -> SendSummaryTitleProvider {
        StakingSendSummaryTitleProvider(actionType: actionType.sendFlowActionType, tokenItem: tokenItem, walletName: userWalletInfo.name)
    }
}

extension StakingAction.ActionType {
    var sendFlowActionType: SendFlowActionType {
        switch self {
        case .stake, .pending(.stake): .stake
        case .unstake: .unstake
        case .pending(.claimRewards): .claimRewards
        case .pending(.withdraw): .withdraw
        case .pending(.restakeRewards): .restakeRewards
        case .pending(.voteLocked): .voteLocked
        case .pending(.unlockLocked): .unlockLocked
        case .pending(.restake): .restake
        case .pending(.claimUnstaked): .claimUnstaked
        }
    }
}
