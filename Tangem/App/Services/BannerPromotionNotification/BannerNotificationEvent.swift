//
//  BannerNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum BannerNotificationEvent: Hashable, NotificationEvent {
    case changelly(title: NotificationView.Title, description: String)

    var title: NotificationView.Title {
        switch self {
        case .changelly(let title, _):
            return title
        }
    }

    var description: String? {
        switch self {
        case .changelly(_, let description):
            return description
        }
    }

    var colorScheme: NotificationView.ColorScheme { .tangemExpressPromotion }
    var icon: NotificationView.MessageIcon {
        .init(
            iconType: .image(Assets.swapBannerIcon.image),
            size: CGSize(bothDimensions: 34)
        )
    }

    var severity: NotificationView.Severity { .info }
    var isDismissable: Bool { true }
    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { true }
}
