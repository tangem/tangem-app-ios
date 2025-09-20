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
    case yieldModuleNotification(token: TokenItem, networkFee: String)
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
        case .yieldModuleNotification(let assetSymbol, let networkFee):
            hasher.combine(assetSymbol)
            hasher.combine(networkFee)
        }

        return hasher.finalize()
    }

    var title: NotificationView.Title? {
        switch self {
        case .irreversibleLossNotification(let assetSymbol, let networkName):
            return .string(Localization.receiveBottomSheetWarningTitle(assetSymbol, networkName))
        case .unsupportedTokenWarning(let title, _, _):
            return .string(title)
        case .yieldModuleNotification(let token, _):
            // [REDACTED_TODO_COMMENT]
            return .string("Your \(token.currencySymbol) is deposited in AAVE")
        }
    }

    var description: String? {
        switch self {
        case .irreversibleLossNotification:
            return Localization.receiveBottomSheetWarningMessageDescription
        case .unsupportedTokenWarning(_, let description, _):
            return description
        case .yieldModuleNotification(_, let networkFee):
            // [REDACTED_TODO_COMMENT]
            return "When you top up, funds go to Aave to earn interest, minus a \(networkFee) transaction fee."
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
        case .yieldModuleNotification(let token, _):
            return .init(iconType: .yieldModuleIcon(TokenIconInfoBuilder().build(from: token.id)))
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
