//
//  YieldAPYBoostBannerNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

// [REDACTED_TODO_COMMENT]
struct YieldAPYBoostBannerNotificationEvent: NotificationEvent, Hashable {
    static let deeplink = URL(string: "tangem://earn?earn_type=yield")!

    var id: NotificationViewId { "yieldApyBoostPromo".hashValue }

    var title: NotificationView.Title? {
        var redesignTitle = AttributedString(
            Localization.yieldApyBoostBannerTitle
                + " " + AppConstants.dotSign + " "
                + Localization.yieldApyBoostBannerTitleApyMultiplied
        )
        redesignTitle.setFontStyle(Font.Tangem.Body15.semibold)
        return .attributed(redesignTitle)
    }

    var description: String? { Localization.yieldApyBoostBannerSubtitle }

    var icon: NotificationView.MessageIcon {
        return .init(
            iconType: .image(Assets.YieldModule.yieldMode),
            renderingMode: .template,
            size: .init(bothDimensions: 36)
        )
    }

    var colorScheme: NotificationView.ColorScheme { .primary }
    var severity: NotificationView.Severity { .info }
    var isDismissable: Bool { true }

    var bannerKind: NotificationBannerKind? { .promo(.magic) }

    var buttonAction: NotificationButtonAction? {
        .init(.openYieldBoostPromo(buttonTitle: Localization.yieldApyBoostBannerButtonTitle))
    }

    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { false }
}
