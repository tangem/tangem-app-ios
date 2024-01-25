//
//  VisaNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum VisaNotificationEvent: Hashable {
    case missingRequiredBlockchain
    case notValidBlockchain
    case failedToLoadPaymentAccount
}

extension VisaNotificationEvent: NotificationEvent {
    var title: String {
        "Error"
    }

    var description: String? {
        switch self {
        case .missingRequiredBlockchain:
            return "Failed to find required WalletManager"
        case .notValidBlockchain:
            return "WalletManager doesn't supported Smart Contract interaction"
        case .failedToLoadPaymentAccount:
            return "Failed to find Payment Account address in bridge"
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        return .secondary
    }

    var icon: NotificationView.MessageIcon {
        return .init(iconType: .image(Assets.redCircleWarning.image))
    }

    var severity: NotificationView.Severity {
        return .critical
    }

    var isDismissable: Bool {
        return false
    }
}

// MARK: - Analytics

extension VisaNotificationEvent {
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
