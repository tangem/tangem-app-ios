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
        case .sepa: Localization.notificationSepaTitle
        }
    }

    var description: String? {
        switch self {
        case .sepa: Localization.notificationSepaText
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .sepa:
            .init(
                iconType: .image(Assets.sepaBannerImage.image),
                size: .init(bothDimensions: 54)
            )
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .sepa: .primary
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
