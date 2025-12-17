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
}

extension AddCustomTokenNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .scamWarning:
            return .string(Localization.customTokenValidationErrorNotFoundTitle)
        case .alreadyAdded:
            return .string(Localization.customTokenValidationErrorAlreadyAdded)
        }
    }

    var description: String? {
        switch self {
        case .scamWarning:
            return Localization.customTokenValidationErrorNotFoundDescription
        case .alreadyAdded:
            return nil
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .scamWarning, .alreadyAdded:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .scamWarning, .alreadyAdded:
            return .init(iconType: .image(Assets.attention.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .scamWarning, .alreadyAdded:
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .scamWarning, .alreadyAdded:
            return false
        }
    }

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .scamWarning, .alreadyAdded:
            return nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .scamWarning, .alreadyAdded:
            return [:]
        }
    }

    var isOneShotAnalyticsEvent: Bool {
        switch self {
        case .scamWarning, .alreadyAdded:
            return false
        }
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }
}
