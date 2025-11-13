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

enum TangemPayNotificationEvent: Equatable, Hashable {
    case createAccountAndIssueCard
    case viewKYCStatus
}

extension TangemPayNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .createAccountAndIssueCard:
            return .string(Localization.tangempayIssueCardNotificationTitle)
        case .viewKYCStatus:
            return .string(Localization.tangempayKycInProgressNotificationTitle)
        }
    }

    // [REDACTED_TODO_COMMENT]
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
            return .init(iconType: .image(Assets.Visa.promo.image), size: Constants.defaultIconSize)
        case .viewKYCStatus:
            return .init(iconType: .image(Assets.Visa.kyc.image), size: Constants.defaultIconSize)
        }
    }

    var severity: NotificationView.Severity {
        return .critical
    }

    var isDismissable: Bool {
        return false
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .createAccountAndIssueCard:
            NotificationButtonAction(
                .tangemPayCreateAccountAndIssueCard,
                withLoader: true,
                isDisabled: false
            )

        case .viewKYCStatus:
            NotificationButtonAction(
                .tangemPayViewKYCStatus,
                withLoader: false,
                isDisabled: false
            )
        }
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

private extension TangemPayNotificationEvent {
    enum Constants {
        static let defaultIconSize = CGSize(bothDimensions: 36)
    }
}
