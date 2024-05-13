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
    case travala(description: String)

    var title: NotificationView.Title {
        switch self {
        case .travala:
            return .string(Localization.mainTravalaPromotionTitle)
        case .changelly(let title, _):
            return title
        }
    }

    var description: String? {
        switch self {
        case .changelly(_, let description):
            return description
        case .travala(let description):
            return description
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .changelly:
            return .changellyPromotion
        case .travala:
            return .travalaPromotion
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .changelly:
            return .init(
                iconType: .image(Assets.swapBannerIcon.image),
                size: CGSize(bothDimensions: 34)
            )
        case .travala:
            // Just for hold the place. The icon will be on the background
            return .init(
                iconType: .image(Assets.travalaBannerIcon.image.renderingMode(.template)),
                color: .clear,
                size: CGSize(bothDimensions: 60)
            )
        }
    }

    var severity: NotificationView.Severity { .info }
    var isDismissable: Bool { true }

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .changelly:
            return nil
        case .travala:
            return .promotionBannerAppeared
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .changelly:
            return [:]
        case .travala:
            return [
                .programName: Analytics.ParameterValue.travala.rawValue,
                .source: Analytics.ParameterValue.main.rawValue,
            ]
        }
    }

    var isOneShotAnalyticsEvent: Bool { true }
}
