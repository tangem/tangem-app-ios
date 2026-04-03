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
import TangemUI

enum TangemPayNotificationEvent: Equatable, Hashable {
    case unavailable
    case tangemPayIsNowBeta
}

extension TangemPayNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .unavailable:
            return .string(Localization.tangempayTemporarilyUnavailable)
        case .tangemPayIsNowBeta:
            return .string(Localization.tangemPayBetaNotificationTitle)
        }
    }

    var description: String? {
        switch self {
        case .unavailable:
            return Localization.tangempayServiceUnreachableTryLater
        case .tangemPayIsNowBeta:
            return Localization.tangemPayBetaNotificationSubtitle
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .tangemPayIsNowBeta:
            return .primary
        case .unavailable:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .unavailable:
            return .init(iconType: .image(Assets.warningIcon))
        case .tangemPayIsNowBeta:
            return .init(iconType: .image(Assets.Visa.promo), size: .init(bothDimensions: 36))
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
        case .unavailable, .tangemPayIsNowBeta:
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
