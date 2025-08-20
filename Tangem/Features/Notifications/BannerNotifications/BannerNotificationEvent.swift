//
//  BannerNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

struct BannerNotificationEvent: NotificationEvent {
    let programName: PromotionProgramName
    let analytics: BannerNotificationEventAnalyticsParamsBuilder
    let buttonAction: NotificationButtonAction?

    var id: NotificationViewId { programName.hashValue }
    var title: NotificationView.Title? { .string(programName.title) }
    var description: String? { programName.description }
    var icon: NotificationView.MessageIcon { programName.icon }
    var colorScheme: NotificationView.ColorScheme { programName.colorScheme }
    var severity: NotificationView.Severity { .info }
    var isDismissable: Bool { true }
    var analyticsEvent: Analytics.Event? { .promotionBannerAppeared }
    var analyticsParams: [Analytics.ParameterKey: String] { analytics.analyticsParams }
    var isOneShotAnalyticsEvent: Bool { true }
}

extension PromotionProgramName {
    var title: String {
        switch self {
        case .ring: Localization.ringPromoTitle
        case .onrampSEPAWithMercuryo: "Buy Crypto with SEPA"
        }
    }

    var description: String? {
        switch self {
        case .ring: Localization.ringPromoText
        case .onrampSEPAWithMercuryo: "Enjoy zero fees when purchasing crypto via SEPA transfer."
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .ring:
            .init(
                iconType: .placeholder,
                size: .init(bothDimensions: 60)
            )
        case .onrampSEPAWithMercuryo:
            .init(
                iconType: .image(Assets.sepaBannerImage.image),
                size: .init(bothDimensions: 48)
            )
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .ring: .ring
        case .onrampSEPAWithMercuryo: .action
        }
    }
}

struct BannerNotificationEventAnalyticsParamsBuilder {
    let programName: PromotionProgramName
    let placement: BannerPromotionPlacement

    var analyticsParams: [Analytics.ParameterKey: String] {
        [
            .programName: programName.analyticsValue.rawValue,
            .source: placement.analyticsValue.rawValue,
        ]
    }
}
