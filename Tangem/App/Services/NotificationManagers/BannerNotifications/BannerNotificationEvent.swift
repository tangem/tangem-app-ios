//
//  BannerNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BannerNotificationEvent: NotificationEvent {
    let title: NotificationView.Title
    let description: String?
    let programName: PromotionProgramName
    let placement: BannerPromotionPlacement
    let icon: NotificationView.MessageIcon
    let colorScheme: NotificationView.ColorScheme
    let severity: NotificationView.Severity

    var isDismissable: Bool {
        true
    }

    var analyticsEvent: Analytics.Event? {
        .promotionBannerAppeared
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [
            .programName: programName.analyticsValue.rawValue,
            .source: analyticsSource,
        ]
    }

    var isOneShotAnalyticsEvent: Bool {
        true
    }

    var id: NotificationViewId {
        programName.hashValue
    }

    private var analyticsSource: String {
        switch placement {
        case .main:
            Analytics.ParameterValue.main.rawValue
        case .tokenDetails:
            Analytics.ParameterValue.token.rawValue
        }
    }
}
