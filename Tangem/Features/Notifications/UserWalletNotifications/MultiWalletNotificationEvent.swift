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
    case someTokensNeedYieldApprove
}

// MARK: - NotificationEvent

extension MultiWalletNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .someNetworksUnreachable:
            return .string(Localization.warningSomeNetworksUnreachableTitle)
        case .someTokenBalancesNotUpdated:
            return .none
        case .someTokensNeedYieldApprove:
            return .string(Localization.yieldModuleMainViewApproveNotificationTitle)
        }
    }

    var description: String? {
        switch self {
        case .someNetworksUnreachable:
            return Localization.warningSomeNetworksUnreachableMessage
        case .someTokenBalancesNotUpdated:
            return Localization.warningSomeTokenBalancesNotUpdated
        case .someTokensNeedYieldApprove:
            return Localization.yieldModuleMainViewApproveNotificationDescription
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
        case .someTokensNeedYieldApprove:
            return .init(iconType: .image(Assets.WalletConnect.yellowWarningCircle.image))
        }
    }

    var severity: NotificationView.Severity { .warning }

    var isDismissable: Bool { false }

    var buttonAction: NotificationButtonAction? { .none }

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .someTokenBalancesNotUpdated: return nil // [REDACTED_TODO_COMMENT]
        case .someNetworksUnreachable: return .mainNoticeNetworksUnreachable
        case .someTokensNeedYieldApprove: return nil // YIELD [REDACTED_TODO_COMMENT]
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .someTokenBalancesNotUpdated:
            return [:] // [REDACTED_TODO_COMMENT]
        case .someNetworksUnreachable(let networks):
            return [.tokens: networks.joined(separator: ", ")]
        case .someTokensNeedYieldApprove:
            return [:] // YIELD [REDACTED_TODO_COMMENT]
        }
    }

    var isOneShotAnalyticsEvent: Bool { false }
}
