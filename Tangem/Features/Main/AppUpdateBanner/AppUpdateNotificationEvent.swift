//
//  AppUpdateNotificationEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

struct AppUpdateNotificationEvent: NotificationEvent, Hashable {
    var id: NotificationViewId { hashValue }

    var title: NotificationView.Title? {
        .string(Localization.forceUpdateBannerTitle)
    }

    var description: String? {
        Localization.forceUpdateBannerMessage
    }

    var colorScheme: NotificationView.ColorScheme {
        .primary
    }

    var icon: NotificationView.MessageIcon {
        .init(iconType: .image(Assets.warningIcon))
    }

    var severity: NotificationView.Severity {
        .warning
    }

    var isDismissable: Bool {
        false
    }

    var buttonAction: NotificationButtonAction? {
        NotificationButtonAction(.openAppStore)
    }

    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { false }
}
