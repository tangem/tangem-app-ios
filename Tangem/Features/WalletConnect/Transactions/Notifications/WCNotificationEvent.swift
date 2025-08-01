//
//  WCNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import SwiftUI
import TangemAssets

enum WCNotificationEvent: Equatable {
    case customFeeTooHigh(orderOfMagnitude: Int)
    case customFeeTooLow
    case insufficientBalance
    case insufficientBalanceForFee
    case networkFeeUnreachable
    case suspiciousTransaction(description: String?)
    case maliciousTransaction(description: String?)
}

extension WCNotificationEvent {
    enum NotificationType {
        case feeValidation
        case simulationValidation
    }

    var notificationType: NotificationType {
        switch self {
        case .customFeeTooHigh, .customFeeTooLow, .insufficientBalance, .insufficientBalanceForFee, .networkFeeUnreachable:
            return .feeValidation
        case .suspiciousTransaction, .maliciousTransaction:
            return .simulationValidation
        }
    }
}

extension WCNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        switch self {
        case .customFeeTooHigh: "wcCustomFeeTooHigh".hashValue
        case .customFeeTooLow: "wcCustomFeeTooLow".hashValue
        case .insufficientBalance: "wcInsufficientBalance".hashValue
        case .insufficientBalanceForFee: "wcInsufficientBalanceForFee".hashValue
        case .networkFeeUnreachable: "wcNetworkFeeUnreachable".hashValue
        case .suspiciousTransaction: "wcSuspiciousTransaction".hashValue
        case .maliciousTransaction: "wcMaliciousTransaction".hashValue
        }
    }

    var title: NotificationView.Title? {
        switch self {
        case .customFeeTooHigh:
            return .string(Localization.sendNotificationFeeTooHighTitle)
        case .customFeeTooLow:
            return .string(Localization.sendNotificationTransactionDelayTitle)
        case .insufficientBalance:
            return .string(Localization.sendNotificationExceedBalanceTitle)
        case .insufficientBalanceForFee:
            return .string(Localization.warningSendBlockedFundsForFeeTitle(""))
        case .networkFeeUnreachable:
            return .string(Localization.sendFeeUnreachableErrorTitle)
        case .suspiciousTransaction:
            return .string(BlockaidChainScanResult.ValidationStatus.warning.rawValue)
        case .maliciousTransaction:
            return .string(BlockaidChainScanResult.ValidationStatus.malicious.rawValue)
        }
    }

    var description: String? {
        switch self {
        case .customFeeTooHigh(let orderOfMagnitude):
            return Localization.sendNotificationFeeTooHighText(orderOfMagnitude)
        case .customFeeTooLow:
            return Localization.sendNotificationTransactionDelayText
        case .insufficientBalance:
            return Localization.sendNotificationExceedBalanceText
        case .insufficientBalanceForFee:
            return Localization.warningBlockedFundsForFeeTitle
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorText
        case .suspiciousTransaction(let description):
            return description ?? "Suspicious transaction detected"
        case .maliciousTransaction(let description):
            return description ?? "Malicious transaction detected"
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .customFeeTooHigh, .customFeeTooLow, .suspiciousTransaction:
            return .secondary
        case .insufficientBalance, .insufficientBalanceForFee, .networkFeeUnreachable, .maliciousTransaction:
            return .action
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .customFeeTooHigh, .customFeeTooLow, .suspiciousTransaction:
            return .init(iconType: .image(Assets.attention.image))
        case .insufficientBalance, .insufficientBalanceForFee, .networkFeeUnreachable, .maliciousTransaction:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .customFeeTooHigh, .customFeeTooLow, .suspiciousTransaction:
            return .warning
        case .insufficientBalance, .insufficientBalanceForFee, .networkFeeUnreachable, .maliciousTransaction:
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

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .networkFeeUnreachable:
            return NotificationButtonAction(.refreshFee, withLoader: false)
        default:
            return nil
        }
    }
}
