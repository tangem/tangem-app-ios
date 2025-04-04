//
//  ReceiveNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

struct ReceiveNotificationEvent {
    let assetSymbol: String
    let networkName: String
}

extension ReceiveNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        assetSymbol.hashValue
    }

    var title: NotificationView.Title? {
        .string(Localization.receiveBottomSheetWarningTitle(assetSymbol, networkName))
    }

    var description: String? {
        Localization.receiveBottomSheetWarningMessageDescription
    }

    var colorScheme: NotificationView.ColorScheme {
        .secondary
    }

    var icon: NotificationView.MessageIcon {
        .init(iconType: .image(Assets.blueCircleWarning.image))
    }

    var severity: NotificationView.Severity {
        .info
    }

    var isDismissable: Bool {
        false
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }

    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        false
    }
}
