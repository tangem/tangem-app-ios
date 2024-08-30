//
//  StakingNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

enum StakingNotificationEvent {
    case approveTransactionInProgress
    case stake(tokenSymbol: String, rewardScheduleType: RewardScheduleType)
    case unstake(periodFormatted: String)
    case withdraw
    case validationErrorEvent(ValidationErrorEvent)
    case networkUnreachable
    case feeWillBeSubtractFromSendingAmount(cryptoAmountFormatted: String, fiatAmountFormatted: String)
}

extension StakingNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        switch self {
        case .approveTransactionInProgress: "approveTransactionInProgress".hashValue
        case .feeWillBeSubtractFromSendingAmount: "feeWillBeSubtractFromSendingAmount".hashValue
        case .stake: "stake".hashValue
        case .unstake: "unstake".hashValue
        case .withdraw: "withdraw".hashValue
        case .validationErrorEvent(let validationErrorEvent): validationErrorEvent.id
        case .networkUnreachable: "networkUnreachable".hashValue
        }
    }

    var title: NotificationView.Title {
        switch self {
        case .approveTransactionInProgress: .string(Localization.warningExpressApprovalInProgressTitle)
        case .feeWillBeSubtractFromSendingAmount: .string(Localization.sendNetworkFeeWarningTitle)
        case .stake: .string(Localization.stakingNotificationEarnRewardsTitle)
        case .unstake: .string(Localization.commonUnstake)
        case .withdraw: .string(Localization.stakingWithdraw)
        case .validationErrorEvent(let event): event.title
        case .networkUnreachable: .string(Localization.sendFeeUnreachableErrorTitle)
        }
    }

    var description: String? {
        switch self {
        case .approveTransactionInProgress:
            Localization.warningExpressApprovalInProgressMessage
        case .feeWillBeSubtractFromSendingAmount(let cryptoAmountFormatted, let fiatAmountFormatted):
            Localization.commonNetworkFeeWarningContent(cryptoAmountFormatted, fiatAmountFormatted)
        case .stake(let tokenSymbol, .hour):
            Localization.stakingNotificationEarnRewardsTextPeriodHour(tokenSymbol)
        case .stake(let tokenSymbol, .day):
            Localization.stakingNotificationEarnRewardsTextPeriodDay(tokenSymbol)
        case .stake(let tokenSymbol, .week):
            Localization.stakingNotificationEarnRewardsTextPeriodWeek(tokenSymbol)
        case .stake(let tokenSymbol, .month):
            Localization.stakingNotificationEarnRewardsTextPeriodMonth(tokenSymbol)
        case .unstake(let periodFormatted):
            Localization.stakingNotificationUnstakeText(periodFormatted)
        case .withdraw:
            Localization.stakingNotificationWithdrawText
        case .validationErrorEvent(let event):
            event.description
        case .networkUnreachable:
            Localization.sendFeeUnreachableErrorText
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .approveTransactionInProgress, .feeWillBeSubtractFromSendingAmount: .secondary
        case .stake, .unstake, .networkUnreachable, .withdraw: .action
        case .validationErrorEvent(let event): event.colorScheme
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkUnreachable, .feeWillBeSubtractFromSendingAmount:
            return .init(iconType: .image(Assets.attention.image))
        case .approveTransactionInProgress:
            return .init(iconType: .progressView)
        case .stake, .unstake, .withdraw:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        case .validationErrorEvent(let event):
            return event.icon
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .networkUnreachable:
            return .critical
        case .approveTransactionInProgress, .stake, .unstake, .feeWillBeSubtractFromSendingAmount, .withdraw:
            return .info
        case .validationErrorEvent(let event):
            return event.severity
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .networkUnreachable:
            return .init(.refreshFee)
        case .validationErrorEvent(let event):
            return event.buttonAction
        case .approveTransactionInProgress, .stake, .unstake, .feeWillBeSubtractFromSendingAmount, .withdraw:
            return nil
        }
    }

    var isDismissable: Bool {
        false
    }

    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        true
    }
}
