//
//  SendNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

enum SendNotificationEvent {
    case networkFeeUnreachable
    // When fee currency is same as fee currency
    case totalExceedsBalance(configuration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration)
    // When fee currency is different
    case feeExceedsBalance(configuration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration)
    case customFeeTooHigh(orderOfMagnitude: Int)
    case customFeeTooLow
    case feeCoverage
    case minimumAmount(value: String)
    case invalidReserve(value: String)
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
        case .customFeeTooHigh:
            return .string(Localization.sendNotificationFeeTooHighTitle)
        case .customFeeTooLow:
            return .string(Localization.sendNotificationTransactionDelayTitle)
        case .feeCoverage:
            return .string(Localization.sendNetworkFeeWarningTitle)
        case .minimumAmount:
            return .string(Localization.sendNotificationInvalidAmountTitle)
        case .invalidReserve(let value):
            return .string(Localization.sendNotificationInvalidReserveAmountTitle(value))
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
        case .customFeeTooHigh(let orderOfMagnitude):
            return Localization.sendNotificationFeeTooHighText(orderOfMagnitude)
        case .customFeeTooLow:
            return Localization.sendNotificationTransactionDelayText
        case .feeCoverage:
            return Localization.sendNetworkFeeWarningContent
        case .minimumAmount(let value):
            return Localization.sendNotificationInvalidMinimumAmountText(value)
        case .invalidReserve:
            return Localization.sendNotificationInvalidReserveAmountText

        case .withdrawalOptionalAmountChange(_, let amount):
            return Localization.sendNotificationHighFeeText(amount)
        case .withdrawalMandatoryAmountChange(_, let amountFormatted, let blockchainName, let maxUtxo):
            return Localization.sendNotificationTransactionLimitText(blockchainName, maxUtxo, amountFormatted)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkFeeUnreachable, .totalExceedsBalance, .feeExceedsBalance, .withdrawalOptionalAmountChange, .withdrawalMandatoryAmountChange:
            return .primary
        case .customFeeTooHigh, .customFeeTooLow, .feeCoverage, .minimumAmount, .invalidReserve:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .minimumAmount, .invalidReserve, .withdrawalOptionalAmountChange, .withdrawalMandatoryAmountChange:
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .networkFeeUnreachable, .customFeeTooHigh, .customFeeTooLow, .feeCoverage:
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Assets.attention.image))
        case .totalExceedsBalance(let configuration), .feeExceedsBalance(let configuration):
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Image(configuration.feeAmountTypeIconName)))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .minimumAmount, .invalidReserve, .withdrawalOptionalAmountChange, .withdrawalMandatoryAmountChange:
            // ⚠️ sync with SendNotificationEvent.icon
            return .critical
        case .networkFeeUnreachable, .customFeeTooHigh, .customFeeTooLow, .feeCoverage:
            // ⚠️ sync with SendNotificationEvent.icon
            return .warning
        case .totalExceedsBalance, .feeExceedsBalance:
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
        case .networkFeeUnreachable, .totalExceedsBalance, .feeExceedsBalance:
            return .feeLevels
        case .customFeeTooHigh, .customFeeTooLow:
            return .customFee
        case .feeCoverage:
            return .feeIncluded
        case .minimumAmount, .invalidReserve, .withdrawalOptionalAmountChange, .withdrawalMandatoryAmountChange:
            return .summary
        }
    }
}

extension SendNotificationEvent {
    var buttonActionTypes: [NotificationButtonActionType]? {
        switch self {
        case .networkFeeUnreachable:
            return [.refreshFee]
        case .totalExceedsBalance(let configuration), .feeExceedsBalance(let configuration):
            return [.openFeeCurrency(currencySymbol: configuration.feeAmountTypeCurrencySymbol)]
        case .withdrawalOptionalAmountChange(let amount, let amountFormatted):
            return [.reduceBy(amount: amount, amountFormatted: amountFormatted)]
        case .withdrawalMandatoryAmountChange(let amount, let amountFormatted, _, _):
            return [.reduceTo(amount: amount, amountFormatted: amountFormatted)]
        case .customFeeTooHigh, .customFeeTooLow, .feeCoverage, .minimumAmount, .invalidReserve:
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
        case .customFeeTooHigh:
            "customFeeTooHigh"
        case .customFeeTooLow:
            "customFeeTooLow"
        case .feeCoverage:
            "feeCoverage"
        case .minimumAmount:
            "minimumAmount"
        case .invalidReserve:
            "invalidReserve"
        case .withdrawalOptionalAmountChange:
            "withdrawalOptionalAmountChange"
        case .withdrawalMandatoryAmountChange:
            "withdrawalMandatoryAmountChange"
        }
    }
}
