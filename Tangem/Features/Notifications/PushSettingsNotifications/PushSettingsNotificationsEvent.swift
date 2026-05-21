//
//  PushSettingsNotificationsEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemUI
import TangemLocalization

enum PushSettingsNotificationsEvent: Hashable {
    case allowNotifications
}

extension PushSettingsNotificationsEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .allowNotifications:
            return .string(Localization.pushNotificationSettingsBannerTitle)
        }
    }

    var description: String? {
        switch self {
        case .allowNotifications:
            return Localization.pushNotificationSettingsBannerDescription
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        .primary
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .allowNotifications:
            return .init(iconType: .image(Assets.attention))
        }
    }

    var severity: NotificationView.Severity {
        .warning
    }

    var isDismissable: Bool {
        false
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }
}

// MARK: - Analytics

extension PushSettingsNotificationsEvent {
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
