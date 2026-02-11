//
//  ActionButtonsNotificationEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

enum ActionButtonsNotificationEvent: Hashable {
    case refreshRequired(title: String, message: String)
    case noAvailablePairs
    case swapNotSupportedForToken(tokenName: String)
    case sellRegionalRestriction
}

extension ActionButtonsNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .refreshRequired(let title, _):
            return .string(title)
        case .noAvailablePairs:
            return .string(Localization.actionButtonsSwapNoAvailablePairNotificationTitle)
        case .swapNotSupportedForToken(let tokenName):
            return .string(Localization.expressSwapNotSupportedTitle(tokenName))
        case .sellRegionalRestriction:
            return .string(Localization.sellingRegionalRestrictionAlertTitle)
        }
    }

    var description: String? {
        switch self {
        case .refreshRequired(_, let message):
            return message
        case .noAvailablePairs:
            return Localization.actionButtonsSwapNoAvailablePairNotificationMessage
        case .swapNotSupportedForToken:
            return Localization.expressSwapNotSupportedText
        case .sellRegionalRestriction:
            return Localization.sellingRegionalRestrictionAlertMessage
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .refreshRequired, .noAvailablePairs, .swapNotSupportedForToken, .sellRegionalRestriction: .action
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .refreshRequired, .swapNotSupportedForToken: .init(iconType: .image(Assets.attention.image))
        case .noAvailablePairs, .sellRegionalRestriction: .init(iconType: .image(Assets.warningIcon.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .refreshRequired: .critical
        case .noAvailablePairs, .swapNotSupportedForToken, .sellRegionalRestriction: .warning
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .refreshRequired: .init(.refresh, withLoader: false)
        case .noAvailablePairs, .swapNotSupportedForToken, .sellRegionalRestriction: nil
        }
    }

    var removingOnFullLoadingState: Bool {
        switch self {
        case .refreshRequired, .noAvailablePairs, .swapNotSupportedForToken, .sellRegionalRestriction: return false
        }
    }

    var isDismissable: Bool {
        return false
    }
}

// MARK: Analytics

extension ActionButtonsNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        switch self {
        default:
            nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        default:
            [:]
        }
    }

    var isOneShotAnalyticsEvent: Bool {
        return false
    }
}
