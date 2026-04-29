//
//  TangemPayCardDeactivatedNotificationEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayCardDeactivatedNotificationEvent: NotificationEvent, Equatable, Hashable {}

extension TangemPayCardDeactivatedNotificationEvent {
    var title: NotificationView.Title? {
        .string(Localization.tangempayAccountDeactivatedMessageTitle)
    }

    var description: String? {
        Localization.tangempayAccountDeactivatedMessageSubtitle
    }

    var colorScheme: NotificationView.ColorScheme {
        .secondary
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
        nil
    }
}

// MARK: - Analytics

extension TangemPayCardDeactivatedNotificationEvent {
    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { false }
}
