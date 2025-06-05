//
//  ExpressProvidersEvents.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

enum ExpressProvidersListEvent: NotificationEvent {
    case fcaWarningList

    var title: NotificationView.Title? {
        switch self {
        case .fcaWarningList: .string(Localization.warningExpressProvidersFcaWarningTitle)
        }
    }

    var description: String? {
        switch self {
        case .fcaWarningList: Localization.warningExpressProvidersFcaWarningDescription
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .fcaWarningList: .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .fcaWarningList: .init(iconType: .image(Assets.redCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .fcaWarningList: .warning
        }
    }

    var isDismissable: Bool { false }

    var buttonAction: NotificationButtonAction? { .none }

    var analyticsEvent: Analytics.Event? { .none }

    var analyticsParams: [Analytics.ParameterKey: String] { [:] }

    var isOneShotAnalyticsEvent: Bool { false }
}
