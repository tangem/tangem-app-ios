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
    case feeExceedsBalance(configuration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration)
    case customFeeTooHigh(orderOfMagnitude: Int)
    case customFeeTooLow
    case feeCoverage
    case minimumAmount(value: String)
}

extension SendNotificationEvent: NotificationEvent {
    var title: String {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorTitle
        case .feeExceedsBalance(let configuration):
            return Localization.warningSendBlockedFundsForFeeTitle(configuration.networkName)
        case .customFeeTooHigh:
            return Localization.sendNotificationFeeTooHighTitle
        case .customFeeTooLow:
            return Localization.sendNotificationTransactionDelayTitle
        case .feeCoverage:
            return Localization.sendNetworkFeeWarningTitle
        case .minimumAmount:
            return Localization.sendNotificationInvalidAmountTitle
        }
    }

    var description: String? {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorText
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
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkFeeUnreachable, .feeExceedsBalance:
            return .primary
        case .customFeeTooHigh, .customFeeTooLow, .feeCoverage, .minimumAmount:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .minimumAmount:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .networkFeeUnreachable, .customFeeTooHigh, .customFeeTooLow, .feeCoverage:
            return .init(iconType: .image(Assets.attention.image))
        case .feeExceedsBalance(let configuration):
            return .init(iconType: .image(Image(configuration.feeAmountTypeIconName)))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .networkFeeUnreachable, .customFeeTooHigh, .customFeeTooLow, .feeCoverage, .feeExceedsBalance, .minimumAmount:
            return .critical
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
        case .customFeeTooHigh, .customFeeTooLow:
            return .customFee
        case .feeCoverage:
            return .feeIncluded
        case .minimumAmount:
            return .summary
        }
    }
}

extension SendNotificationEvent {
    var buttonActionType: NotificationButtonActionType? {
        switch self {
        case .networkFeeUnreachable:
            return .refreshFee
        case .feeExceedsBalance(let configuration):
            return .openFeeCurrency(currencySymbol: configuration.feeAmountTypeCurrencySymbol)
        case .customFeeTooHigh, .customFeeTooLow, .feeCoverage, .minimumAmount:
            return nil
        }
    }
}
