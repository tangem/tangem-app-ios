//
//  TokenNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum TokenNotificationEvent: Hashable {
    struct NotEnoughFeeConfiguration: Hashable {
        let isFeeCurrencyPurchaseAllowed: Bool
        let eventConfiguration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration
    }

    // [REDACTED_TODO_COMMENT]
    enum UnfulfilledRequirementsConfiguration {
        case missingHederaTokenAssociation
        @available(*, unavailable, message: "Token trust lines support not implemented yet")
        case missingTokenTrustline
    }

    case networkUnreachable(currencySymbol: String)
    case someNetworksUnreachable
    case rentFee(rentMessage: String)
    case noAccount(message: String)
    case existentialDepositWarning(message: String)
    case notEnoughFeeForTransaction(configuration: NotEnoughFeeConfiguration)
    case solanaHighImpact
    case hasUnfulfilledRequirements(configuration: UnfulfilledRequirementsConfiguration)

    static func event(
        for reason: TransactionSendAvailabilityProvider.SendingRestrictions,
        isFeeCurrencyPurchaseAllowed: Bool
    ) -> TokenNotificationEvent? {
        guard let message = reason.description else {
            return nil
        }

        switch reason {
        case .zeroWalletBalance, .hasPendingTransaction, .blockchainUnreachable, .cantSignLongTransactions:
            return nil
        case .zeroFeeCurrencyBalance(let eventConfiguration):
            let configuration = NotEnoughFeeConfiguration(
                isFeeCurrencyPurchaseAllowed: isFeeCurrencyPurchaseAllowed,
                eventConfiguration: eventConfiguration
            )
            return .notEnoughFeeForTransaction(configuration: configuration)
        }
    }

    var buttonAction: NotificationButtonActionType? {
        switch self {
        // One notification with button action will be added later
        case .networkUnreachable,
             .someNetworksUnreachable,
             .rentFee,
             .existentialDepositWarning,
             .noAccount,
             .solanaHighImpact:
            return nil
        case .notEnoughFeeForTransaction(let configuration):
            let eventConfig = configuration.eventConfiguration
            return configuration.isFeeCurrencyPurchaseAllowed
                ? .openFeeCurrency(currencySymbol: eventConfig.currencyButtonTitle ?? eventConfig.feeAmountTypeCurrencySymbol)
                : nil
        case .hasUnfulfilledRequirements(.missingHederaTokenAssociation):
            return .addHederaTokenAssociation
        }
    }
}

extension TokenNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .networkUnreachable:
            return .string(Localization.warningNetworkUnreachableTitle)
        case .someNetworksUnreachable:
            return .string(Localization.warningSomeNetworksUnreachableTitle)
        case .rentFee:
            return .string(Localization.warningRentFeeTitle)
        case .noAccount:
            return .string(Localization.warningNoAccountTitle)
        case .existentialDepositWarning:
            return .string(Localization.warningExistentialDepositTitle)
        case .notEnoughFeeForTransaction(let configuration):
            return .string(Localization.warningSendBlockedFundsForFeeTitle(configuration.eventConfiguration.feeAmountTypeName))
        case .solanaHighImpact:
            return .string(Localization.warningSolanaFeeTitle)
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .string("Associate your token") // [REDACTED_TODO_COMMENT]
        }
    }

    var description: String? {
        switch self {
        case .networkUnreachable:
            return Localization.warningNetworkUnreachableMessage
        case .someNetworksUnreachable:
            return Localization.warningSomeNetworksUnreachableMessage
        case .rentFee(let message):
            return message
        case .noAccount(let message):
            return message
        case .existentialDepositWarning(let message):
            return message
        case .notEnoughFeeForTransaction(let configuration):
            return Localization.warningSendBlockedFundsForFeeMessage(
                configuration.eventConfiguration.transactionAmountTypeName,
                configuration.eventConfiguration.networkName,
                configuration.eventConfiguration.transactionAmountTypeName,
                configuration.eventConfiguration.feeAmountTypeName,
                configuration.eventConfiguration.feeAmountTypeCurrencySymbol
            )
        case .solanaHighImpact:
            return Localization.warningSolanaFeeMessage
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return "This token must be associated with your Hedera account before you can receive it. Association fee X HBAR" // [REDACTED_TODO_COMMENT]
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkUnreachable,
             .someNetworksUnreachable,
             .rentFee,
             .existentialDepositWarning,
             .noAccount,
             .solanaHighImpact:
            return .secondary
        // One white notification will be added later
        case .notEnoughFeeForTransaction:
            return .primary
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .action
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkUnreachable, .someNetworksUnreachable, .solanaHighImpact:
            return .init(iconType: .image(Assets.attention.image))
        case .rentFee, .noAccount, .existentialDepositWarning:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        case .notEnoughFeeForTransaction(let configuration):
            return .init(iconType: .image(Image(configuration.eventConfiguration.feeAmountTypeIconName)))
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .init(iconType: .image(Tokens.hederaFill.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .noAccount,
             .rentFee,
             .existentialDepositWarning:
            return .info
        case .networkUnreachable,
             .someNetworksUnreachable,
             .notEnoughFeeForTransaction,
             .solanaHighImpact:
            return .warning
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .critical // [REDACTED_TODO_COMMENT]
        }
    }

    var isDismissable: Bool {
        switch self {
        case .rentFee:
            return true
        case .networkUnreachable,
             .someNetworksUnreachable,
             .existentialDepositWarning,
             .notEnoughFeeForTransaction,
             .noAccount,
             .solanaHighImpact,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return false
        }
    }
}

// MARK: Analytics info

extension TokenNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        switch self {
        case .networkUnreachable: return .tokenNoticeNetworkUnreachable
        case .someNetworksUnreachable: return .mainNoticeNetworksUnreachable
        case .rentFee: return nil
        case .noAccount: return nil
        case .existentialDepositWarning: return nil
        case .notEnoughFeeForTransaction: return .tokenNoticeNotEnoughFee
        case .solanaHighImpact: return nil
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation): return nil // [REDACTED_TODO_COMMENT]
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .networkUnreachable(let currencySymbol):
            return [.token: currencySymbol]
        case .notEnoughFeeForTransaction(let configuration):
            return [.token: configuration.eventConfiguration.feeAmountTypeCurrencySymbol]
        case .someNetworksUnreachable,
             .rentFee,
             .noAccount,
             .existentialDepositWarning,
             .solanaHighImpact,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return [:]
        }
    }

    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool { false }
}
