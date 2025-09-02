//
//  TangemPayNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemFoundation
import TangemAssets

enum TangemPayNotificationEvent {
    case createAccountAndIssueCard
    case viewKYCStatus
}

extension TangemPayNotificationEvent {
    static func == (lhs: TangemPayNotificationEvent, rhs: TangemPayNotificationEvent) -> Bool {
        switch (lhs, rhs) {
        case (.createAccountAndIssueCard, .createAccountAndIssueCard): return true
        case (.viewKYCStatus, .viewKYCStatus): return true
        case (.createAccountAndIssueCard, _),
             (.viewKYCStatus, _):
            return false
        }
    }
}

// [REDACTED_TODO_COMMENT]
extension TangemPayNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        var hasher = Hasher()
        hasher.combine(String(describing: self))
        return hasher.finalize()
    }

    var title: NotificationView.Title? {
        switch self {
        case .createAccountAndIssueCard:
            return .string("Create account and issue a card")
        case .viewKYCStatus:
            return .string("KYC in progress for Tangem Pay")
        }
    }

    var description: String? {
        switch self {
        case .createAccountAndIssueCard:
            return "Write description here. In one, two or three lines will be awesome"
        case .viewKYCStatus:
            return "Write description here. In one, two or three lines will be awesome"
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .createAccountAndIssueCard,
             .viewKYCStatus:
            return .primary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .createAccountAndIssueCard:
            return .init(iconType: .image(Assets.Visa.promo.image), size: .init(bothDimensions: 36))
        case .viewKYCStatus:
            return .init(iconType: .image(Assets.Visa.kyc.image), size: .init(bothDimensions: 36))
        }
    }

    var severity: NotificationView.Severity {
        return .critical
    }

    var isDismissable: Bool {
        return false
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }
}

// MARK: - Analytics

extension TangemPayNotificationEvent {
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
