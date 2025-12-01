//
//  TangemPayNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemFoundation
import TangemAssets

enum TangemPayNotificationEvent: Equatable, Hashable {
    case syncNeeded
    case unavailable
}

extension TangemPayNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .syncNeeded:
            return .string(Localization.tangempayPaymentAccountSyncNeeded)
        case .unavailable:
            return .string(Localization.tangempayTemporarilyUnavailable)
        }
    }

    var description: String? {
        switch self {
        case .syncNeeded:
            return Localization.tangempayUseTangemDeviceToRestorePaymentAccount
        case .unavailable:
            return Localization.tangempayServiceUnreachableTryLater
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .syncNeeded:
            return .primary
        case .unavailable:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .syncNeeded, .unavailable:
            return .init(iconType: .image(Assets.warningIcon.image))
        }
    }

    var severity: NotificationView.Severity {
        return .critical
    }

    var isDismissable: Bool {
        return false
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .syncNeeded:
            NotificationButtonAction(
                .tangemPaySync,
                withLoader: true,
                isDisabled: false
            )

        case .unavailable:
            nil
        }
    }
}

// MARK: - Analytics

extension TangemPayNotificationEvent {
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

private extension TangemPayNotificationEvent {
    enum Constants {
        static let defaultIconSize = CGSize(bothDimensions: 36)
    }
}
