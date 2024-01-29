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
    case feeCoverage
}

extension SendNotificationEvent: NotificationEvent {
    var title: String {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorTitle
        case .feeCoverage:
            return Localization.sendNetworkFeeWarningTitle
        }
    }

    var description: String? {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorText
        case .feeCoverage:
            return Localization.sendNetworkFeeWarningContent
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkFeeUnreachable:
            return .primary
        case .feeCoverage:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkFeeUnreachable, .feeCoverage:
            return .init(iconType: .image(Assets.attention.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .networkFeeUnreachable, .feeCoverage:
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
        case feeIncluded
    }

    var location: Location {
        switch self {
        case .networkFeeUnreachable:
            return .feeLevels
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
        case .feeCoverage:
            return nil
        }
    }
}
