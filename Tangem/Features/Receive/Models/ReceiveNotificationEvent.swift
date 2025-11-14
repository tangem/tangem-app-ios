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
    case yieldModuleNotification(tokenSymbol: String, tokenId: String?)
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
        case .yieldModuleNotification(let symbol, let id):
            hasher.combine(symbol)
            hasher.combine(id)
        }

        return hasher.finalize()
    }

    var title: NotificationView.Title? {
        switch self {
        case .irreversibleLossNotification(let assetSymbol, let networkName):
            return .string(Localization.receiveBottomSheetWarningTitle(assetSymbol, networkName))
        case .unsupportedTokenWarning(let title, _, _):
            return .string(title)
        case .yieldModuleNotification(let symbol, _):
            return .string(Localization.yieldModuleAlertTitle(symbol))
        }
    }

    var description: String? {
        switch self {
        case .irreversibleLossNotification:
            return Localization.receiveBottomSheetWarningMessageDescription
        case .unsupportedTokenWarning(_, let description, _):
            return description
        case .yieldModuleNotification(let symbol, _):
            return Localization.yieldModuleEarnSheetProviderDescription(symbol, "a\(symbol)")
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
        case .yieldModuleNotification(_, let id):
            return .init(iconType: .yieldModuleIcon(tokenId: id))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .irreversibleLossNotification, .yieldModuleNotification:
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
