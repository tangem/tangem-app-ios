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
        if FeatureProvider.isAvailable(.redesign) {
            var redesignTitle = AttributedString(
                Localization.yieldApyBoostBannerTitle
                    + " " + AppConstants.dotSign + " "
                    + Localization.yieldApyBoostBannerTitleApyMultiplied
            )
            redesignTitle.setFontStyle(Font.Tangem.Body15.semibold)
            return .attributed(redesignTitle)
        }

        var title = AttributedString(Localization.yieldApyBoostBannerTitle + " ")
        title.foregroundColor = Colors.Text.primary1
        title.font = Fonts.Bold.footnote

        var dot = AttributedString(AppConstants.dotSign + " ")
        dot.foregroundColor = Colors.Text.tertiary
        dot.font = Fonts.Regular.footnote

        var apy = AttributedString(Localization.yieldApyBoostBannerTitleApyMultiplied)
        apy.foregroundColor = Colors.Text.accent
        apy.font = Fonts.Bold.footnote

        return .attributed(title + dot + apy)
    }

    var description: String? { Localization.yieldApyBoostBannerSubtitle }

    var icon: NotificationView.MessageIcon {
        if FeatureProvider.isAvailable(.redesign) {
            return .init(
                iconType: .image(Assets.YieldModule.yieldMode),
                renderingMode: .template,
                size: .init(bothDimensions: 36)
            )
        }

        return .init(iconType: .image(Assets.YieldModule.yieldMode))
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
