//
//  SendReceiveTokensListNotification.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemAssets

enum SendReceiveTokensListNotification: NotificationEvent {
    case sendWithSwapInfo

    var title: NotificationView.Title? {
        switch self {
        case .sendWithSwapInfo:
            return .string(Localization.sendWithSwapTitle)
        }
    }

    var description: String? {
        switch self {
        case .sendWithSwapInfo:
            return Localization.sendWithSwapNotificationText
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .sendWithSwapInfo:
            return .init(iconType: .image(Assets.refreshWarningIcon.image.renderingMode(.template)), color: Colors.Icon.accent)
        }
    }

    var isDismissable: Bool { true }
    var severity: NotificationView.Severity { .info }
    var colorScheme: NotificationView.ColorScheme { .secondary }
    var buttonAction: NotificationButtonAction? { .none }
    var analyticsEvent: Analytics.Event? { .none }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { false }
}
