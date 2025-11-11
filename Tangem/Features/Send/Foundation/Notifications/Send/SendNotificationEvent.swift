//
//  SendNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Foundation
import TangemLocalization
import TangemAssets
import TangemMacro

@RawCaseName
@CaseFlagable
enum SendNotificationEvent: Hashable {
    // The send flow specific notifications
    case networkFeeUnreachable
    case feeWillBeSubtractFromSendingAmount(
        cryptoAmountFormatted: String,
        fiatAmountFormatted: String,
        amountCurrencySymbol: String
    )
    case customFeeTooHigh(orderOfMagnitude: Int)
    case customFeeTooLow
    case accountNotActivated(assetName: String)

    // Generic notifications is received from BSDK
    case withdrawalNotificationEvent(WithdrawalNotificationEvent)
    case validationErrorEvent(ValidationErrorEvent)

    /// Blockchain specific
    case oneSuiCoinIsRequiredForTokenTransaction(currencySymbol: String)
}

extension SendNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .networkFeeUnreachable:
            return .string(Localization.sendFeeUnreachableErrorTitle)
        case .feeWillBeSubtractFromSendingAmount:
            return .string(Localization.sendNetworkFeeWarningTitle)
        case .customFeeTooHigh:
            return .string(Localization.sendNotificationFeeTooHighTitle)
        case .customFeeTooLow:
            return .string(Localization.sendNotificationTransactionDelayTitle)
        case .withdrawalNotificationEvent(let event):
            return event.title
        case .validationErrorEvent(let event):
            return event.title
        case .accountNotActivated:
            return .string(Localization.sendFeeUnreachableErrorTitle)
        case .oneSuiCoinIsRequiredForTokenTransaction:
            return .string(Localization.suiNotEnoughCoinForFeeTitle)
        }
    }

    var description: String? {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorText
        case .feeWillBeSubtractFromSendingAmount(let cryptoAmountFormatted, let fiatAmountFormatted, _):
            return Localization.commonNetworkFeeWarningContent(cryptoAmountFormatted, fiatAmountFormatted)
        case .customFeeTooHigh(let orderOfMagnitude):
            return Localization.sendNotificationFeeTooHighText(orderOfMagnitude)
        case .customFeeTooLow:
            return Localization.sendNotificationTransactionDelayText
        case .withdrawalNotificationEvent(let event):
            return event.description
        case .validationErrorEvent(let event):
            return event.description
        case .accountNotActivated(let assetName):
            return Localization.sendTronAccountActivationError(assetName)
        case .oneSuiCoinIsRequiredForTokenTransaction(let currencySymbol):
            let oneSui = "1 \(currencySymbol)"
            return Localization.suiNotEnoughCoinForFeeDescription(oneSui)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkFeeUnreachable,
             .validationErrorEvent(.insufficientBalance):
            return .action
        case .feeWillBeSubtractFromSendingAmount,
             .customFeeTooHigh,
             .customFeeTooLow:
            return .secondary
        case .withdrawalNotificationEvent(let event):
            return event.colorScheme
        case .validationErrorEvent(let event):
            return event.colorScheme
        case .accountNotActivated, .oneSuiCoinIsRequiredForTokenTransaction:
            return .action
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkFeeUnreachable,
             .customFeeTooHigh,
             .customFeeTooLow,
             .feeWillBeSubtractFromSendingAmount:
            return .init(iconType: .image(Assets.attention.image))
        case .withdrawalNotificationEvent(let event):
            return event.icon
        case .validationErrorEvent(let event):
            return event.icon
        case .accountNotActivated, .oneSuiCoinIsRequiredForTokenTransaction:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .networkFeeUnreachable,
             .customFeeTooHigh,
             .customFeeTooLow,
             .feeWillBeSubtractFromSendingAmount:
            return .warning
        case .withdrawalNotificationEvent(let event):
            return event.severity
        case .validationErrorEvent(let event):
            return event.severity
        case .accountNotActivated, .oneSuiCoinIsRequiredForTokenTransaction:
            return .critical
        }
    }

    var isDismissable: Bool {
        switch self {
        case .withdrawalNotificationEvent(.reduceAmountBecauseFeeIsTooHigh):
            return true
        default:
            return false
        }
    }

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .feeWillBeSubtractFromSendingAmount:
            return Analytics.Event.sendNoticeNetworkFeeCoverage
        case .validationErrorEvent(let validationEvent):
            switch validationEvent {
            case .insufficientBalanceForFee:
                return Analytics.Event.sendNoticeNotEnoughFee
            default:
                return nil
            }
        default:
            return nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .feeWillBeSubtractFromSendingAmount(_, _, let amountCurrencySymbol):
            return [.token: amountCurrencySymbol]

        case .validationErrorEvent(let validationEvent):
            switch validationEvent {
            case .insufficientBalanceForFee(let configuration):
                return [
                    .token: configuration.amountCurrencySymbol,
                    .blockchain: configuration.amountCurrencyBlockchainName,
                ]

            default:
                return [:]
            }

        default:
            return [:]
        }
    }

    var isOneShotAnalyticsEvent: Bool {
        false
    }
}

extension SendNotificationEvent {
    var buttonAction: NotificationButtonAction? {
        switch self {
        case .networkFeeUnreachable:
            return .init(.refreshFee, withLoader: true)
        case .feeWillBeSubtractFromSendingAmount,
             .customFeeTooHigh,
             .customFeeTooLow,
             .accountNotActivated:
            return nil
        case .withdrawalNotificationEvent(let event):
            return event.buttonAction
        case .validationErrorEvent(let event):
            return event.buttonAction
        case .oneSuiCoinIsRequiredForTokenTransaction(let currencySymbol):
            return .init(.openFeeCurrency(currencySymbol: currencySymbol))
        }
    }
}
