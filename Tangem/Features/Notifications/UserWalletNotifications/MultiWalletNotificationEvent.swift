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
    case initialWalletTokenSyncCompleted
}

// MARK: - NotificationEvent

extension MultiWalletNotificationEvent: NotificationEvent {
    var bannerKind: NotificationBannerKind? {
        switch self {
        case .initialWalletTokenSyncCompleted:
            return .informational
        case .someTokenBalancesNotUpdated, .someNetworksUnreachable:
            return .status
        }
    }

    var title: NotificationView.Title? {
        switch self {
        case .someNetworksUnreachable:
            return .string(Localization.warningSomeNetworksUnreachableTitle)
        case .someTokenBalancesNotUpdated:
            return .none
        case .initialWalletTokenSyncCompleted:
            return .string(Localization.initialWalletSyncBannerTitle)
        }
    }

    var description: String? {
        switch self {
        case .someNetworksUnreachable:
            return Localization.warningSomeNetworksUnreachableMessage
        case .someTokenBalancesNotUpdated:
            return Localization.warningSomeTokenBalancesNotUpdated
        case .initialWalletTokenSyncCompleted:
            return Localization.initialWalletSyncBannerDescription
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        .secondary
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .someNetworksUnreachable:
            return .init(iconType: .image(Assets.attention))
        case .someTokenBalancesNotUpdated:
            return .init(iconType: .image(Assets.failedCloud), color: Colors.Icon.attention)
        case .initialWalletTokenSyncCompleted:
            return .init(iconType: .image(Assets.blueCircleWarning))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .initialWalletTokenSyncCompleted:
            return .info
        case .someTokenBalancesNotUpdated, .someNetworksUnreachable:
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .initialWalletTokenSyncCompleted:
            return true
        case .someTokenBalancesNotUpdated, .someNetworksUnreachable:
            return false
        }
    }

    var buttonAction: NotificationButtonAction? { .none }

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .someTokenBalancesNotUpdated: return nil // [REDACTED_TODO_COMMENT]
        case .someNetworksUnreachable: return .mainNoticeNetworksUnreachable
        case .initialWalletTokenSyncCompleted: return nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .someTokenBalancesNotUpdated:
            return [:] // [REDACTED_TODO_COMMENT]
        case .someNetworksUnreachable(let networks):
            return [.tokens: networks.joined(separator: ", ")]
        case .initialWalletTokenSyncCompleted:
            return [:]
        }
    }

    var isOneShotAnalyticsEvent: Bool { false }
}
