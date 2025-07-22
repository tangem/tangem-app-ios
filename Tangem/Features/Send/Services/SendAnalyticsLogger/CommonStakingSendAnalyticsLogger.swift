//
//  CommonStakingSendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStaking

class CommonStakingSendAnalyticsLogger {
    private let tokenItem: TokenItem
    private let actionType: SendFlowActionType

    private weak var stakingValidatorsInput: StakingValidatorsInput?

    init(
        tokenItem: TokenItem,
        actionType: SendFlowActionType
    ) {
        self.tokenItem = tokenItem
        self.actionType = actionType
    }
}

// MARK: - SendValidatorsAnalyticsLogger

extension CommonStakingSendAnalyticsLogger: SendValidatorsAnalyticsLogger {
    func logStakingValidatorChosen() {
        Analytics.log(
            event: .stakingValidatorChosen,
            params: [.validator: stakingValidatorsInput?.selectedValidator?.name ?? ""]
        )
    }
}

// MARK: - StakingAnalyticsLogger

extension CommonStakingSendAnalyticsLogger: StakingAnalyticsLogger {
    func logError(_ error: any Error, currencySymbol: String) {
        CommonStakingAnalyticsLogger().logError(error, currencySymbol: currencySymbol)
    }
}

// MARK: - SendAmountAnalyticsLogger

extension CommonStakingSendAnalyticsLogger: SendAmountAnalyticsLogger {
    func logTapMaxAmount() {
        Analytics.log(event: .stakingButtonMax, params: [.token: tokenItem.currencySymbol])
    }

    func logAmountStepOpened() {
        Analytics.log(event: .stakingAmountScreenOpened, params: [.token: tokenItem.currencySymbol])
    }

    func logAmountStepReopened() {
        Analytics.log(
            event: .stakingScreenReopened,
            params: [
                .source: Analytics.ParameterValue.amount.rawValue,
                .token: tokenItem.currencySymbol,
            ]
        )
    }
}

// MARK: - SendBaseViewAnalyticsLogger

extension CommonStakingSendAnalyticsLogger: StakingSendAnalyticsLogger {
    func setup(stakingValidatorsInput: any StakingValidatorsInput) {
        self.stakingValidatorsInput = stakingValidatorsInput
    }
}

// MARK: - SendSummaryAnalyticsLogger

extension CommonStakingSendAnalyticsLogger: SendSummaryAnalyticsLogger {
    func logUserDidTapOnValidator() {
        Analytics.log(
            event: .stakingButtonValidator,
            params: [
                .source: Analytics.ParameterValue.stakeSourceConfirmation.rawValue,
                .token: tokenItem.currencySymbol,
            ]
        )
    }

    func logSummaryStepOpened() {
        Analytics.log(
            event: .stakingConfirmationScreenOpened,
            params: [
                .validator: stakingValidatorsInput?.selectedValidator?.address ?? "",
                .action: actionType.stakingAnalyticsAction?.rawValue ?? "",
                .token: tokenItem.currencySymbol,
                .blockchain: tokenItem.blockchain.displayName,
            ]
        )
    }
}

// MARK: - SendFinishAnalyticsLogger

extension CommonStakingSendAnalyticsLogger: SendFinishAnalyticsLogger {
    func logFinishStepOpened() {
        guard let stakingAnalyticsAction = actionType.stakingAnalyticsAction else {
            return
        }

        Analytics.log(event: .stakingStakeInProgressScreenOpened, params: [
            .validator: stakingValidatorsInput?.selectedValidator?.name ?? "",
            .token: tokenItem.currencySymbol,
            .action: stakingAnalyticsAction.rawValue,
        ])
    }
}

// MARK: - SendBaseViewAnalyticsLogger

extension CommonStakingSendAnalyticsLogger: SendBaseViewAnalyticsLogger {
    func logShareButton() {
        Analytics.log(
            event: .stakingButtonShare,
            params: [
                .token: tokenItem.currencySymbol,
            ]
        )
    }

    func logExploreButton() {
        Analytics.log(
            event: .stakingButtonExplore,
            params: [.token: tokenItem.currencySymbol]
        )
    }

    func logRequestSupport() {
        Analytics.log(.requestSupport, params: [.source: .send])
    }

    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool) {
        Analytics.log(event: .stakingButtonCancel, params: [
            .source: stepType.analyticsSourceParameterValue.rawValue,
            .token: tokenItem.currencySymbol,
        ])
    }

    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {
        var actionParameters: [Analytics.ParameterKey: String] = [
            .validator: stakingValidatorsInput?.selectedValidator?.name ?? "",
            .token: tokenItem.currencySymbol,
        ]

        switch (type, flow) {
        case (.next, .stake):
            Analytics.log(event: .stakingButtonNext, params: [.token: tokenItem.currencySymbol])
        case (.action, .stake):
            actionParameters[.source] = Analytics.ParameterValue.stakeSourceConfirmation.rawValue
            Analytics.log(event: .stakingButtonStake, params: actionParameters)
        case (.action, .unstake):
            Analytics.log(event: .stakingButtonUnstake, params: actionParameters)
        case (.action, .withdraw):
            Analytics.log(event: .stakingButtonWithdraw, params: actionParameters)
        case (.action, .claimRewards):
            Analytics.log(event: .stakingButtonClaim, params: actionParameters)
        case (.action, .restakeRewards):
            Analytics.log(event: .stakingButtonRestake, params: actionParameters)
        default:
            break
        }
    }

    func logSendBaseViewOpened() {
        switch actionType {
        case .claimRewards, .restakeRewards:
            Analytics.log(
                event: .stakingRewardScreenOpened,
                params: [
                    .validator: stakingValidatorsInput?.selectedValidator?.address ?? "",
                    .token: tokenItem.currencySymbol,
                ]
            )
        default:
            break
        }
    }
}

// MARK: - SendManagementModelAnalyticsLogger

extension CommonStakingSendAnalyticsLogger: SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: Error) {
        Analytics.log(event: .stakingErrorTransactionRejected, params: [
            .token: tokenItem.currencySymbol,
            .errorCode: "\(error.universalErrorCode)",
            .blockchain: tokenItem.blockchain.displayName,
        ])
    }

    func logTransactionSent(amount: SendAmount?, additionalField: SendDestinationAdditionalField?, fee: SendFee, signerType: String) {
        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.transactionSourceStaking.rawValue,
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: fee.option.rawValue,
            .walletForm: signerType,
        ])

        switch amount?.type {
        case .none:
            break

        case .typical:
            Analytics.log(
                event: .stakingSelectedCurrency,
                params: [
                    .commonType: Analytics.ParameterValue.token.rawValue,
                    .token: tokenItem.currencySymbol,
                ]
            )

        case .alternative:
            Analytics.log(
                event: .stakingSelectedCurrency,
                params: [
                    .commonType: Analytics.ParameterValue.selectedCurrencyApp.rawValue,
                    .token: tokenItem.currencySymbol,
                ]
            )
        }
    }
}

private extension SendFlowActionType {
    var stakingAnalyticsAction: Analytics.ParameterValue? {
        switch self {
        case .stake: .stakeActionStake
        case .unstake: .stakeActionUnstake
        case .claimRewards: .stakeActionClaimRewards
        case .restakeRewards: .stakeActionRestakeRewards
        case .withdraw, .claimUnstaked: .stakeActionWithdraw
        case .restake: .stakeActionRestake
        case .unlockLocked: .stakeActionUnlockLocked
        case .stakeLocked: .stakeActionStakeLocked
        case .vote: .stakeActionVote
        case .revoke: .stakeActionRevoke
        case .voteLocked: .stakeActionVoteLocked
        case .revote: .stakeActionRevote
        case .rebond: .stakeActionRebond
        case .migrate: .stakeActionMigrate
        default: nil
        }
    }
}
