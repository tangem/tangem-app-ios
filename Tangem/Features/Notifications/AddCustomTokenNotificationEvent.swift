//
//  AddCustomTokenNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets

enum AddCustomTokenNotificationEvent: Hashable {
    case scamWarning
    case alreadyAdded
    case dynamicAddressesEnabled
}

extension AddCustomTokenNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .scamWarning:
            return .string(Localization.customTokenValidationErrorNotFoundTitle)
        case .alreadyAdded:
            return .string(Localization.customTokenValidationErrorAlreadyAdded)
        case .dynamicAddressesEnabled:
            return .string(Localization.customTokenCustomDerivationDynamicAddressesEnabledError)
        }
    }

    var description: String? {
        switch self {
        case .scamWarning:
            return Localization.customTokenValidationErrorNotFoundDescription
        case .alreadyAdded, .dynamicAddressesEnabled:
            return nil
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .scamWarning, .alreadyAdded, .dynamicAddressesEnabled:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .scamWarning, .alreadyAdded, .dynamicAddressesEnabled:
            return .init(iconType: .image(Assets.attention))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .scamWarning, .alreadyAdded, .dynamicAddressesEnabled:
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .scamWarning, .alreadyAdded, .dynamicAddressesEnabled:
            return false
        }
    }

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .scamWarning, .alreadyAdded, .dynamicAddressesEnabled:
            return nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .scamWarning, .alreadyAdded, .dynamicAddressesEnabled:
            return [:]
        }
    }

    var isOneShotAnalyticsEvent: Bool {
        switch self {
        case .scamWarning, .alreadyAdded, .dynamicAddressesEnabled:
            return false
        }
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }
}
