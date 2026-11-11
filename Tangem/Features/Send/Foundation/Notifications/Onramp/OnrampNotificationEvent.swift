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
    case countryNotSupported
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
        case .countryNotSupported:
            return .string(Localization.onrampResidencyBottomsheetCountryNotSupported)
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
        case .countryNotSupported:
            return Localization.onrampSettingsResidenceDescription
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .refreshRequired:
            return .action
        case .tokenNotSupported, .providersRestricted, .countryNotSupported:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .refreshRequired, .tokenNotSupported, .providersRestricted, .countryNotSupported:
            return .init(iconType: .image(Assets.attention))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .refreshRequired:
            return .critical
        case .tokenNotSupported, .providersRestricted, .countryNotSupported:
            return .warning
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .refreshRequired:
            return .init(.refresh, withLoader: true)
        case .countryNotSupported:
            return .init(.changeOnrampCountry)
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
