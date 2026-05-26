//
//  AddFundsNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

struct AddFundsNotificationEvent: NotificationEvent, Hashable {
    var id: NotificationViewId { hashValue }

    var title: NotificationView.Title? {
        .string(Localization.mainAddFundsPromoTitle)
    }

    var description: String? {
        Localization.mainAddFundsPromoDescription
    }

    var colorScheme: NotificationView.ColorScheme {
        .primary
    }

    var icon: NotificationView.MessageIcon {
        .init(
            iconType: .image(Assets.coinsSwap),
            size: CGSize(width: 24, height: 24)
        )
    }

    var severity: NotificationView.Severity {
        .info
    }

    var isDismissable: Bool {
        false
    }

    var buttonAction: NotificationButtonAction? {
        NotificationButtonAction(.addFunds)
    }

    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { false }
}
