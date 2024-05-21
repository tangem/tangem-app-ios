//
//  WithdrawalNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

// Warning/Information Notifications
enum WithdrawalNotificationEvent {
    case withdrawalOptionalAmountChange(amount: Decimal, amountFormatted: String, blockchainName: String)
    case cardanoWillBeSentWithToken(cardanoAmountFormatted: String, tokenSymbol: String)
}

// Express | Send
extension WithdrawalNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .withdrawalOptionalAmountChange:
            // The fee is higher |
            return .string(Localization.sendNotificationHighFeeTitle)
        case .cardanoWillBeSentWithToken:
            return .string(Localization.cardanoCoinWillBeSendWithTokenTitle)
        }
    }

    var description: String? {
        switch self {
        case .withdrawalOptionalAmountChange(_, let amount, let blockchainName):
            // Due to the peculiarities of the %1$@ network, the fee for transferring the entire balance is higher. To reduce the commission, you can leave %2$@.
            return Localization.sendNotificationHighFeeText(amount, blockchainName)
        case .cardanoWillBeSentWithToken(let cardanoAmountFormatted, let tokenSymbol):
            return Localization.cardanoCoinWillBeSendWithTokenDescription(cardanoAmountFormatted, tokenSymbol)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        let hasButton = buttonActionType != nil
        if hasButton {
            return .action
        }

        return .secondary
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .withdrawalOptionalAmountChange,
             .cardanoWillBeSentWithToken:
            return .init(iconType: .image(Assets.attention.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .withdrawalOptionalAmountChange,
             .cardanoWillBeSentWithToken:
            return .warning
        }
    }

    var isDismissable: Bool {
        return false
    }
}

// MARK: Button

extension WithdrawalNotificationEvent {
    var buttonActionType: NotificationButtonActionType? {
        switch self {
        case .withdrawalOptionalAmountChange(let amount, let amountFormatted, _):
            return .reduceAmountBy(amount: amount, amountFormatted: amountFormatted)
        case .cardanoWillBeSentWithToken:
            return nil
        }
    }
}

// MARK: Analytics

extension WithdrawalNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        return nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        return [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        return false
    }
}
