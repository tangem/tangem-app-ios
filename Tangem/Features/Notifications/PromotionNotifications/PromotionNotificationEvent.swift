//
//  PromotionNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import Foundation

struct PromotionNotificationEvent: NotificationEvent {
    let promotion: Promotion
    let buttonAction: NotificationButtonAction?

    var id: NotificationViewId { promotion.id }
    var title: NotificationView.Title? { .string(promotion.title) }
    var description: String? { promotion.subtitle }
    var icon: NotificationView.MessageIcon {
        if let iconUrl = promotion.iconUrl {
            return .init(iconType: .loadableIcon(url: iconUrl))
        }
        return .init(iconType: .placeholder)
    }

    var colorScheme: NotificationView.ColorScheme { promotion.placeholder == .main ? .primary : .action }
    var severity: NotificationView.Severity { .info }
    var isDismissable: Bool { promotion.dismissable }

    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] {
        [
            .displayId: "\(promotion.id)",
            .placeholder: promotion.placeholder.rawValue,
        ]
    }

    var isOneShotAnalyticsEvent: Bool { false }
}
