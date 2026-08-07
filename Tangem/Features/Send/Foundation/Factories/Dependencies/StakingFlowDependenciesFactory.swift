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
    var stakingableToken: SendStakingableToken { get }
    var actionType: StakingAction.ActionType { get }
}

extension StakingFlowDependenciesFactory {
    var userWalletInfo: UserWalletInfo { stakingableToken.userWalletInfo }
    var tokenItem: TokenItem { stakingableToken.tokenItem }
    var feeTokenItem: TokenItem { stakingableToken.feeTokenItem }
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

    func makeStakingFeeIncludedCalculator() -> FeeIncludedCalculator {
        StakingFeeIncludedCalculator(tokenItem: tokenItem, validator: stakingableToken.transactionValidator)
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

    func makeValidationHandler(
        stakingManager: StakingManager,
        blockaidAPIKey: String,
        analyticsLogger: StakingSendAnalyticsLogger
    ) -> StakingValidationHandler? {
        guard let validationProvider = makeValidationProvider(blockaidAPIKey: blockaidAPIKey, analyticsLogger: analyticsLogger) else {
            return nil
        }

        return StakingValidationHandler(
            stakingManager: stakingManager,
            validationProvider: validationProvider
        )
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

private extension StakingFlowDependenciesFactory {
    func makeValidationProvider(
        blockaidAPIKey: String,
        analyticsLogger: StakingSendAnalyticsLogger
    ) -> StakingValidationProvider? {
        guard FeatureProvider.isAvailable(.stakingTransactionValidation) else {
            return nil
        }

        let blockchain = tokenItem.blockchain

        // Native ETH staking goes through P2P (not StakeKit) and is out of validation scope.
        if case .ethereum = blockchain, !tokenItem.isToken {
            return nil
        }

        let isLocalValidationEnabled = LocalStakingSupportedNetwork(blockchain: blockchain) != nil
        let isRemoteValidationEnabled = RemoteValidationNetwork(blockchain: blockchain) != nil

        guard isLocalValidationEnabled || isRemoteValidationEnabled else {
            return nil
        }

        let validator = StakingValidationComposer.make(
            blockchain: blockchain,
            accountAddress: stakingableToken.defaultAddressString,
            verifier: StakingTransactionVerifierFactory.make(apiKey: blockaidAPIKey)
        )

        return StakingValidationService(
            validator: validator,
            analyticsLogger: analyticsLogger
        )
    }
}
