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
    case irreversibleLossNotification

    var title: NotificationView.Title? {
        switch self {
        case .sendWithSwapInfo:
            return .string(Localization.sendWithSwapTitle)
        case .irreversibleLossNotification:
            return .string(Localization.sendWithSwapCorrectRecipientNetworkNotificationTitle)
        }
    }

    var description: String? {
        switch self {
        case .sendWithSwapInfo:
            return Localization.sendWithSwapNotificationText
        case .irreversibleLossNotification:
            return Localization.sendWithSwapCorrectRecipientNetworkNotificationMessage
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .sendWithSwapInfo:
            return .init(iconType: .image(Assets.refreshWarningIcon.image.renderingMode(.template)), color: Colors.Icon.accent)
        case .irreversibleLossNotification:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        }
    }

    var isDismissable: Bool {
        switch self {
        case .sendWithSwapInfo: true
        case .irreversibleLossNotification: false
        }
    }

    var severity: NotificationView.Severity { .info }
    var colorScheme: NotificationView.ColorScheme { .secondary }
    var buttonAction: NotificationButtonAction? { .none }
    var analyticsEvent: Analytics.Event? { .none }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { false }
}
