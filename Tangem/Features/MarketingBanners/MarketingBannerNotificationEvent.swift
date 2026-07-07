//
//  MarketingBannerNotificationEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct MarketingBannerNotificationEvent: NotificationEvent {
    let banner: MarketingBanner

    var id: NotificationViewId { banner.id }
    var title: NotificationView.Title? { .string(banner.text) }
    var description: String? { nil }

    var icon: NotificationView.MessageIcon {
        if let iconURL = banner.iconURL {
            return .init(iconType: .loadableIcon(url: iconURL))
        }

        return .init(iconType: .placeholder)
    }

    var colorScheme: NotificationView.ColorScheme { .primary }
    var severity: NotificationView.Severity { .info }
    var isDismissable: Bool { banner.isDismissible }
    var buttonAction: NotificationButtonAction? { nil }
    var bannerKind: NotificationBannerKind? { .promo(.magic) }

    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { false }
}
