//
//  ValidationErrorEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum ValidationErrorEvent {
    // Amount/Fee notifications
    case invalidNumber
    case insufficientBalance
    case insufficientBalanceFee(configuration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration)

    // Blockchain specific notifications
    case dustAmount(minimumAmountText: String, minimumChangeText: String)
    case existentialDepositWarning(amount: Decimal, amountFormatted: String)
    case withdrawalMandatoryAmountChange(amount: Decimal, amountFormatted: String, blockchainName: String, maxUtxo: Int)
    case notEnoughReserveToSwap(minimumAmountText: String)
    case cardanoHasTokens
    case cardanoInsufficientBalanceToSendToken(tokenSymbol: String)
}

// Express | Send
extension ValidationErrorEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .invalidNumber:
            // NaN | NaN
            return .string(Localization.commonError)
        case .insufficientBalance:
            // NaN | Total exceeds balance
            return .string(Localization.sendNotificationExceedBalanceTitle)
        case .insufficientBalanceFee(let configuration):
            // NaN | Insufficient %1$@ to cover network fee
            return .string(Localization.warningSendBlockedFundsForFeeTitle(configuration.feeAmountTypeName))
        case .dustAmount:
            // Invalid amount | Invalid amount
            return .string(Localization.sendNotificationInvalidAmountTitle)
        case .existentialDepositWarning:
            // Network requires Existential Deposit | Existential deposit
            return .string(Localization.warningExistentialDepositTitle)
        case .withdrawalMandatoryAmountChange:
            // Transaction limitation | Transaction limitation
            return .string(Localization.sendNotificationTransactionLimitTitle)
        case .notEnoughReserveToSwap(let minimumAmountText):
            // The amount to send must be at least %@ | Same but in the alert
            return .string(Localization.sendNotificationInvalidReserveAmountTitle(minimumAmountText))
        case .cardanoHasTokens:
            return .string(Localization.sendNotificationInvalidAmountTitle)
        case .cardanoInsufficientBalanceToSendToken:
            return .string(Localization.cardanoInsufficientBalanceToSendTokenTitle)
        }
    }

    var description: String? {
        switch self {
        case .invalidNumber:
            return nil
        case .insufficientBalance:
            // NaN | Insufficient funds for the transfer, as the total of the fee and transfer amount exceeds the existing balance
            return Localization.sendNotificationExceedBalanceText
        case .insufficientBalanceFee(let configuration):
            // NaN | Look below
            return Localization.warningSendBlockedFundsForFeeMessage(
                configuration.transactionAmountTypeName,
                configuration.networkName,
                configuration.transactionAmountTypeName,
                configuration.feeAmountTypeName,
                configuration.feeAmountTypeCurrencySymbol
            )
        case .dustAmount(let minimumAmountText, let minimumChangeText):
            // The minimum swapping amount is %1$@. Please ensure that the remaining balance after the swap will not be less than %2$@. |
            // The minimum sending amount is %1$@. Please ensure that the remaining balance after sending will not be less than %2$@.
            return Localization.warningExpressDustMessage(minimumAmountText, minimumChangeText)
        case .existentialDepositWarning(let blockchainName, let amount):
            // %1$@ network requires an Existential Deposit. If your account drops below %2$@, it will be deactivated, and any remaining funds will be destroyed. |
            // The account will be wiped from the blockchain if a balance goes below the existential deposit. Please leave %@ on your balance.
            return Localization.warningExistentialDepositMessage(blockchainName, amount)
        case .withdrawalMandatoryAmountChange(_, let amountFormatted, let blockchainName, let maxUtxo):
            // Due to %1$@ limitations only %2$@ UTXOs can fit in a single transaction. This means you can only send %3$@ or less. You need to reduce the amount. |
            // Due to %1$@ limitations only %2$@ UTXOs can fit in a single transaction. This means you can only send %3$@ or less. You need to reduce the amount.
            return Localization.sendNotificationTransactionLimitText(blockchainName, maxUtxo, amountFormatted)
        case .notEnoughReserveToSwap(let maximumAmountText):
            // Target account is not created. Please change the amount to send. |
            // TBD on Send
            return Localization.sendNotificationInvalidReserveAmountText
        case .cardanoHasTokens:
            return Localization.cardanoMaxAmountHasTokenDescription
        case .cardanoInsufficientBalanceToSendToken(let tokenSymbol):
            return Localization.cardanoInsufficientBalanceToSendTokenDescription(tokenSymbol)
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
        case .insufficientBalanceFee(let configuration):
            return .init(iconType: .image(Image(configuration.feeAmountTypeIconName)))
        case .invalidNumber,
             .insufficientBalance,
             .dustAmount,
             .existentialDepositWarning,
             .withdrawalMandatoryAmountChange,
             .notEnoughReserveToSwap,
             .cardanoHasTokens,
             .cardanoInsufficientBalanceToSendToken:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .invalidNumber,
             .insufficientBalance,
             .insufficientBalanceFee,
             .dustAmount,
             .existentialDepositWarning,
             .withdrawalMandatoryAmountChange,
             .notEnoughReserveToSwap,
             .cardanoHasTokens,
             .cardanoInsufficientBalanceToSendToken:
            return .critical
        }
    }

    var isDismissable: Bool {
        return false
    }
}

// MARK: Button

extension ValidationErrorEvent {
    var buttonActionType: NotificationButtonActionType? {
        switch self {
        case .insufficientBalanceFee(let configuration):
            return .openFeeCurrency(currencySymbol: configuration.feeAmountTypeCurrencySymbol)
        case .withdrawalMandatoryAmountChange(let amount, let amountFormatted, _, _),
             .existentialDepositWarning(let amount, let amountFormatted):
            return .reduceAmountTo(amount: amount, amountFormatted: amountFormatted)
        case .invalidNumber,
             .insufficientBalance,
             .dustAmount,
             .notEnoughReserveToSwap,
             .cardanoHasTokens,
             .cardanoInsufficientBalanceToSendToken:
            return nil
        }
    }
}

// MARK: Analytics

extension ValidationErrorEvent {
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
