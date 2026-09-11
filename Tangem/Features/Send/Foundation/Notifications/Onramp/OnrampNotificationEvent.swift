//
//  OnrampNotificationEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

enum OnrampNotificationEvent: Hashable {
    case refreshRequired(title: String, message: String)
    case tokenNotSupported(tokenName: String)
    case providersRestricted
}

extension OnrampNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .refreshRequired(let title, _):
            return .string(title)
        case .tokenNotSupported(let tokenName):
            return .string(Localization.onrampTokenIsNotSupportedBannerTitle(tokenName))
        case .providersRestricted:
            return .string(Localization.expressOnrampRestrictionsTitle)
        }
    }

    var description: String? {
        switch self {
        case .refreshRequired(_, let message):
            return message
        case .tokenNotSupported:
            return Localization.onrampTokenIsNotSupportedBannerSubtitle
        case .providersRestricted:
            return Localization.expressOnrampRestrictionsText
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .refreshRequired:
            return .action
        case .tokenNotSupported, .providersRestricted:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .refreshRequired, .tokenNotSupported, .providersRestricted:
            return .init(iconType: .image(Assets.attention))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .refreshRequired:
            return .critical
        case .tokenNotSupported, .providersRestricted:
            return .warning
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .refreshRequired:
            return .init(.refresh, withLoader: true)
        case .tokenNotSupported, .providersRestricted:
            return nil
        }
    }

    var isDismissable: Bool {
        false
    }

    // MARK: - Analytics

    var analyticsEvent: Analytics.Event? { nil }

    var analyticsParams: [Analytics.ParameterKey: String] { [:] }

    var isOneShotAnalyticsEvent: Bool { true }
}
