//
//  HotNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets

enum HotNotificationEvent {
    case finishActivation
}

extension HotNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .finishActivation:
            return .string(Localization.hwActivationNeedTitle)
        }
    }

    var description: String? {
        switch self {
        case .finishActivation:
            Localization.hwActivationNeedDescription
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .finishActivation:
            return .primary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .finishActivation:
            NotificationView.MessageIcon(iconType: .image(Assets.attentionShield.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .finishActivation:
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .finishActivation:
            false
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .finishActivation:
            NotificationButtonAction(.openHotFinishActivation, withLoader: false)
        }
    }

    var analyticsEvent: Analytics.Event? {
        // [REDACTED_TODO_COMMENT]
        switch self {
        case .finishActivation:
            nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        switch self {
        case .finishActivation:
            true
        }
    }
}
