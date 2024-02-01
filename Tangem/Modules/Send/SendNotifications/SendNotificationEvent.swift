//
//  SendNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum SendNotificationEvent {
    case networkFeeUnreachable
    case customFeeTooHigh(orderOfMagnitude: Int)
    case customFeeTooLow
    case feeCoverage
}

extension SendNotificationEvent: NotificationEvent {
    var title: String {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorTitle
        case .customFeeTooHigh:
            return Localization.sendNotificationFeeTooHighTitle
        case .customFeeTooLow:
            return Localization.sendNotificationTransactionDelayTitle
        case .feeCoverage:
            return Localization.sendNetworkFeeWarningTitle
        }
    }

    var description: String? {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorText
        case .customFeeTooHigh(let orderOfMagnitude):
            return Localization.sendNotificationFeeTooHighText(orderOfMagnitude)
        case .customFeeTooLow:
            return Localization.sendNotificationTransactionDelayText
        case .feeCoverage:
            return Localization.sendNetworkFeeWarningContent
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkFeeUnreachable:
            return .primary
        case .customFeeTooHigh, .customFeeTooLow, .feeCoverage:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkFeeUnreachable, .customFeeTooHigh, .feeCoverage:
            return .init(iconType: .image(Assets.attention.image))
        case .customFeeTooLow:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .networkFeeUnreachable, .customFeeTooHigh, .customFeeTooLow, .feeCoverage:
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
    }

    var location: Location {
        switch self {
        case .networkFeeUnreachable:
            return .feeLevels
        case .customFeeTooHigh, .customFeeTooLow:
            return .customFee
        case .feeCoverage:
            return .feeIncluded
        }
    }
}

extension SendNotificationEvent {
    var buttonActionType: NotificationButtonActionType? {
        switch self {
        case .networkFeeUnreachable:
            return .refreshFee
        case .customFeeTooHigh, .customFeeTooLow, .feeCoverage:
            return nil
        }
    }
}
