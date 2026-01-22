//
//  NotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccessibilityIdentifiers

protocol NotificationEvent: Identifiable {
    var id: NotificationViewId { get }
    var title: NotificationView.Title? { get }
    var description: String? { get }
    var colorScheme: NotificationView.ColorScheme { get }
    var icon: NotificationView.MessageIcon { get }
    var severity: NotificationView.Severity { get }
    var isDismissable: Bool { get }
    var buttonAction: NotificationButtonAction? { get }
    // [REDACTED_TODO_COMMENT]
    var analyticsEvent: Analytics.Event? { get }
    var analyticsParams: [Analytics.ParameterKey: String] { get }
    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool { get }
}

extension NotificationEvent where Self: Hashable {
    /// Unique ID. Overwrite if hash value is not enough (may be influenced by associated values)
    var id: NotificationViewId {
        hashValue
    }
}

extension NotificationEvent {
    var accessibilityIdentifier: String? {
        if let generalEvent = self as? GeneralNotificationEvent {
            switch generalEvent {
            case .devCard:
                return MainAccessibilityIdentifiers.developerCardBanner
            case .seedSupport:
                return MainAccessibilityIdentifiers.mandatorySecurityUpdateBanner
            case .missingDerivation:
                return MainAccessibilityIdentifiers.missingDerivationNotification
            default:
                return nil
            }
        } else if let sendNotificationEvent = self as? SendNotificationEvent {
            switch sendNotificationEvent {
            case .networkFeeUnreachable:
                return SendAccessibilityIdentifiers.networkFeeUnreachableBanner
            case .customFeeTooLow:
                return SendAccessibilityIdentifiers.customFeeTooLowBanner
            case .customFeeTooHigh:
                return SendAccessibilityIdentifiers.customFeeTooHighBanner
            case .feeWillBeSubtractFromSendingAmount:
                return SendAccessibilityIdentifiers.feeWillBeSubtractFromSendingAmountBanner
            case .validationErrorEvent(let event):
                switch event {
                case .dustRestriction:
                    return SendAccessibilityIdentifiers.invalidAmountBanner
                case .remainingAmountIsLessThanRentExemption:
                    return SendAccessibilityIdentifiers.remainingAmountIsLessThanRentExemptionBanner
                case .insufficientAmountToReserveAtDestination:
                    return SendAccessibilityIdentifiers.insufficientAmountToReserveAtDestinationBanner
                case .amountExceedMaximumUTXO:
                    return SendAccessibilityIdentifiers.amountExceedMaximumUTXOBanner
                default:
                    return nil
                }
            case .withdrawalNotificationEvent(let withdrawalEvent):
                switch withdrawalEvent {
                case .reduceAmountBecauseFeeIsTooHigh:
                    return SendAccessibilityIdentifiers.highFeeNotificationBanner
                default:
                    return nil
                }
            default:
                return nil
            }
        } else if let tokenEvent = self as? TokenNotificationEvent {
            switch tokenEvent {
            case .noAccount:
                return TokenAccessibilityIdentifiers.topUpWalletBanner
            case .existentialDepositWarning:
                return SendAccessibilityIdentifiers.existentialDepositWarningBanner
            default:
                return nil
            }
        }
        return nil
    }
}
