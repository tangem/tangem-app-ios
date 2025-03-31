//
//  MultiWalletNotificationEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets

enum MultiWalletNotificationEvent: Hashable {
    case someTokenBalancesNotUpdated
    case someNetworksUnreachable(currencySymbols: [String])
}

// MARK: - NotificationEvent

extension MultiWalletNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .someNetworksUnreachable:
            return .string(Localization.warningSomeNetworksUnreachableTitle)
        case .someTokenBalancesNotUpdated:
            return .none
        }
    }

    var description: String? {
        switch self {
        case .someNetworksUnreachable:
            return Localization.warningSomeNetworksUnreachableMessage
        case .someTokenBalancesNotUpdated:
            return Localization.warningSomeTokenBalancesNotUpdated
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        .secondary
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .someNetworksUnreachable:
            return .init(iconType: .image(Assets.attention.image))
        case .someTokenBalancesNotUpdated:
            return .init(iconType: .image(Assets.failedCloud.image), color: Colors.Icon.attention)
        }
    }

    var severity: NotificationView.Severity { .warning }

    var isDismissable: Bool { false }

    var buttonAction: NotificationButtonAction? { .none }

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .someTokenBalancesNotUpdated: return nil // [REDACTED_TODO_COMMENT]
        case .someNetworksUnreachable: return .mainNoticeNetworksUnreachable
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .someTokenBalancesNotUpdated:
            return [:] // [REDACTED_TODO_COMMENT]
        case .someNetworksUnreachable(let networks):
            return [.tokens: networks.joined(separator: ", ")]
        }
    }

    var isOneShotAnalyticsEvent: Bool { false }
}
