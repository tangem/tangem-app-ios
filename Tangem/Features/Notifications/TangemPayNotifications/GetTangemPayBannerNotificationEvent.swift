//
//  GetTangemPayBannerNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemUI

struct GetTangemPayBannerNotificationEvent: NotificationEvent, Hashable {
    var id: NotificationViewId { hashValue }

    var title: NotificationView.Title? {
        .string(Localization.tangempayTangemVisaCard)
    }

    var description: String? {
        Localization.tangempayGetBannerDescription
    }

    var colorScheme: NotificationView.ColorScheme {
        .primary
    }

    var icon: NotificationView.MessageIcon {
        .init(
            iconType: .image(Assets.Visa.cardBanner),
            size: CGSize(width: 52, height: 44)
        )
    }

    var severity: NotificationView.Severity {
        .info
    }

    var isDismissable: Bool {
        true
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }

    var bannerKind: NotificationBannerKind? {
        .promo(.card)
    }

    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { false }
}
