//
//  SendNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SendNotificationEvent {
    case networkFeeUnreachable
    // When fee currency is same as fee currency
    case totalExceedsBalance(configuration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration)
    // When fee currency is different
    case feeExceedsBalance(configuration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration)
    case existentialDeposit(amountFormatted: String)
    case customFeeTooHigh(orderOfMagnitude: Int)
    case customFeeTooLow
    case minimumAmount(value: String)
    case withdrawalOptionalAmountChange(amount: Decimal, amountFormatted: String)
    case withdrawalMandatoryAmountChange(amount: Decimal, amountFormatted: String, blockchainName: String, maxUtxo: Int)
}

extension SendNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .networkFeeUnreachable:
            return .string(Localization.sendFeeUnreachableErrorTitle)
        case .totalExceedsBalance:
            return .string(Localization.sendNotificationExceedBalanceTitle)
        case .feeExceedsBalance(let configuration):
            return .string(Localization.warningSendBlockedFundsForFeeTitle(configuration.networkName))
        case .existentialDeposit:
            return .string(Localization.sendNotificationExistentialDepositTitle)
        case .customFeeTooHigh:
            return .string(Localization.sendNotificationFeeTooHighTitle)
        case .customFeeTooLow:
            return .string(Localization.sendNotificationTransactionDelayTitle)
        case .minimumAmount:
            return .string(Localization.sendNotificationInvalidAmountTitle)
        case .withdrawalOptionalAmountChange:
            return .string(Localization.sendNotificationHighFeeTitle)
        case .withdrawalMandatoryAmountChange:
            return .string(Localization.sendNotificationTransactionLimitTitle)
        }
    }

    var description: String? {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorText
        case .totalExceedsBalance:
            return Localization.sendNotificationExceedBalanceText
        case .feeExceedsBalance(let configuration):
            return Localization.warningSendBlockedFundsForFeeMessage(
                configuration.transactionAmountTypeName,
                configuration.networkName,
                configuration.transactionAmountTypeName,
                configuration.feeAmountTypeName,
                configuration.feeAmountTypeCurrencySymbol
            )
        case .existentialDeposit(let amountFormatted):
            return Localization.sendNotificationExistentialDepositText(amountFormatted)
        case .customFeeTooHigh(let orderOfMagnitude):
            return Localization.sendNotificationFeeTooHighText(orderOfMagnitude)
        case .customFeeTooLow:
            return Localization.sendNotificationTransactionDelayText
        case .minimumAmount(let value):
            return Localization.sendNotificationInvalidMinimumAmountText(value, value)
        case .withdrawalOptionalAmountChange(_, let amount):
            return Localization.sendNotificationHighFeeText(amount)
        case .withdrawalMandatoryAmountChange(_, let amountFormatted, let blockchainName, let maxUtxo):
            return Localization.sendNotificationTransactionLimitText(blockchainName, maxUtxo, amountFormatted)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkFeeUnreachable, .totalExceedsBalance, .withdrawalOptionalAmountChange, .withdrawalMandatoryAmountChange:
            // ♿️ Does it have a button? Use `action`
            return .action
        case .feeExceedsBalance, .existentialDeposit:
            return .primary
        case .customFeeTooHigh, .customFeeTooLow, .minimumAmount:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .minimumAmount, .withdrawalMandatoryAmountChange:
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .networkFeeUnreachable, .existentialDeposit, .customFeeTooHigh, .customFeeTooLow, .withdrawalOptionalAmountChange:
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Assets.attention.image))
        case .totalExceedsBalance(let configuration), .feeExceedsBalance(let configuration):
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Image(configuration.feeAmountTypeIconName)))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .minimumAmount, .withdrawalMandatoryAmountChange:
            // ⚠️ sync with SendNotificationEvent.icon
            return .critical
        case .networkFeeUnreachable, .existentialDeposit, .customFeeTooHigh, .customFeeTooLow, .withdrawalOptionalAmountChange, .totalExceedsBalance:
            // ⚠️ sync with SendNotificationEvent.icon
            return .warning
        case .feeExceedsBalance:
            // ⚠️ sync with SendNotificationEvent.icon
            return .critical
        }
    }

    var isDismissable: Bool {
        switch self {
        case .withdrawalOptionalAmountChange:
            true
        default:
            false
        }
    }

    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        false
    }
}

extension SendNotificationEvent {
    enum Location {
        case feeLevels
        case customFee
        case feeIncluded
        case summary
    }

    var location: Location {
        switch self {
        case .networkFeeUnreachable, .feeExceedsBalance:
            return .feeLevels
        case .customFeeTooHigh:
            return .customFee
        case .minimumAmount, .existentialDeposit, .withdrawalOptionalAmountChange, .withdrawalMandatoryAmountChange, .totalExceedsBalance, .customFeeTooLow:
            return .summary
        }
    }
}

extension SendNotificationEvent {
    // ♿️ Does it have a button? Use `action` color scheme then ☝️
    var buttonActionType: NotificationButtonActionType? {
        switch self {
        case .networkFeeUnreachable:
            return .refreshFee
        case .totalExceedsBalance(let configuration), .feeExceedsBalance(let configuration):
            return .openFeeCurrency(currencySymbol: configuration.feeAmountTypeCurrencySymbol)
        case .withdrawalOptionalAmountChange(let amount, let amountFormatted):
            return .reduceAmountBy(amount: amount, amountFormatted: amountFormatted)
        case .withdrawalMandatoryAmountChange(let amount, let amountFormatted, _, _):
            return .reduceAmountTo(amount: amount, amountFormatted: amountFormatted)
        case .existentialDeposit, .customFeeTooHigh, .customFeeTooLow, .minimumAmount:
            return nil
        }
    }
}

extension SendNotificationEvent {
    var id: String {
        switch self {
        case .networkFeeUnreachable:
            "networkFeeUnreachable"
        case .totalExceedsBalance:
            "totalExceedsBalance"
        case .feeExceedsBalance:
            "feeExceedsBalance"
        case .existentialDeposit:
            "existentialDeposit"
        case .customFeeTooHigh:
            "customFeeTooHigh"
        case .customFeeTooLow:
            "customFeeTooLow"
        case .minimumAmount:
            "minimumAmount"
        case .withdrawalOptionalAmountChange:
            "withdrawalOptionalAmountChange"
        case .withdrawalMandatoryAmountChange:
            "withdrawalMandatoryAmountChange"
        }
    }
}
