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
        .init(
            iconType: .image(DesignSystem.Icons.Error.regular20),
            renderingMode: .template,
            color: .Tangem.Graphic.Neutral.primary,
            isLeading: true,
            usesExactSize: true
        )
    }

    var severity: NotificationView.Severity {
        .critical
    }

    var isDismissable: Bool {
        false
    }

    var buttonAction: NotificationButtonAction? {
        NotificationButtonAction(.removeTangemPayAccount)
    }
}

// MARK: - Analytics

extension TangemPayCardDeactivatedNotificationEvent {
    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { false }
}
