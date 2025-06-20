//
//  ReceiveNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

enum ReceiveNotificationEvent {
    case irreversibleLossNotification(assetSymbol: String, networkName: String)
    case unsupportedTokenWarning(title: String, description: String, tokenItem: TokenItem)
}

// MARK: - NotificationEvent protocol conformance

extension ReceiveNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        var hasher = Hasher()

        switch self {
        case .irreversibleLossNotification(let assetSymbol, let networkName):
            hasher.combine(assetSymbol)
            hasher.combine(networkName)
        case .unsupportedTokenWarning(_, _, let tokenItem):
            hasher.combine(tokenItem)
        }

        return hasher.finalize()
    }

    var title: NotificationView.Title? {
        switch self {
        case .irreversibleLossNotification(let assetSymbol, let networkName):
            return .string(Localization.receiveBottomSheetWarningTitle(assetSymbol, networkName))
        case .unsupportedTokenWarning(let title, _, _):
            return .string(title)
        }
    }

    var description: String? {
        switch self {
        case .irreversibleLossNotification:
            return Localization.receiveBottomSheetWarningMessageDescription
        case .unsupportedTokenWarning(_, let description, _):
            return description
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        .secondary
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .irreversibleLossNotification:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        case .unsupportedTokenWarning:
            return .init(iconType: .image(Assets.warningIcon.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .irreversibleLossNotification:
            return .info
        case .unsupportedTokenWarning:
            return .warning
        }
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
