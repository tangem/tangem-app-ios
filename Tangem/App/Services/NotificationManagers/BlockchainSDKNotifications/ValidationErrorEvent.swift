//
//  ValidationErrorEvent.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum ValidationErrorEvent {
    // Amount/Fee notifications
    case invalidNumber
    case insufficientBalance
    case insufficientBalanceForFee(configuration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration)

    // Blockchain specific notifications
    case dustRestriction(minimumAmountFormatted: String, minimumChangeFormatted: String)
    case existentialDeposit(amount: Decimal, amountFormatted: String)
    case amountExceedMaximumUTXO(amount: Decimal, amountFormatted: String, blockchainName: String, maxUTXO: Int)
    case insufficientAmountToReserveAtDestination(minimumAmountFormatted: String)
    case cardanoCannotBeSentBecauseHasTokens
    case cardanoInsufficientBalanceToSendToken(tokenSymbol: String)

    case notEnoughMana(current: Decimal, max: Decimal)
    case invalidMaxAmount(validMax: Decimal)
}

extension ValidationErrorEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .invalidNumber:
            return .string(Localization.commonError)
        case .insufficientBalance:
            return .string(Localization.sendNotificationExceedBalanceTitle)
        case .insufficientBalanceForFee(let configuration):
            return .string(Localization.warningSendBlockedFundsForFeeTitle(configuration.feeAmountTypeName))
        case .dustRestriction:
            return .string(Localization.sendNotificationInvalidAmountTitle)
        case .existentialDeposit:
            return .string(Localization.sendNotificationExistentialDepositTitle)
        case .amountExceedMaximumUTXO:
            return .string(Localization.sendNotificationTransactionLimitTitle)
        case .insufficientAmountToReserveAtDestination(let minimumAmountText):
            return .string(Localization.sendNotificationInvalidReserveAmountTitle(minimumAmountText))
        case .cardanoCannotBeSentBecauseHasTokens:
            return .string(Localization.sendNotificationInvalidAmountTitle)
        case .cardanoInsufficientBalanceToSendToken:
            return .string(Localization.cardanoInsufficientBalanceToSendTokenTitle)
        case .notEnoughMana:
            return .string("Not enough Mana")
        case .invalidMaxAmount:
            return .string("Mana limit")
        }
    }

    var description: String? {
        switch self {
        case .invalidNumber:
            return nil
        case .insufficientBalance:
            return Localization.sendNotificationExceedBalanceText
        case .insufficientBalanceForFee(let configuration):
            return Localization.warningSendBlockedFundsForFeeMessage(
                configuration.transactionAmountTypeName,
                configuration.networkName,
                configuration.transactionAmountTypeName,
                configuration.feeAmountTypeName,
                configuration.feeAmountTypeCurrencySymbol
            )
        case .dustRestriction(let minimumAmountText, let minimumChangeText):
            return Localization.sendNotificationInvalidMinimumAmountText(minimumAmountText, minimumChangeText)
        case .existentialDeposit(_, let amountFormatted):
            return Localization.sendNotificationExistentialDepositText(amountFormatted)
        case .amountExceedMaximumUTXO(_, let amountFormatted, let blockchainName, let maxUtxo):
            return Localization.sendNotificationTransactionLimitText(blockchainName, maxUtxo, amountFormatted)
        case .insufficientAmountToReserveAtDestination:
            return Localization.sendNotificationInvalidReserveAmountText
        case .cardanoCannotBeSentBecauseHasTokens:
            return Localization.cardanoMaxAmountHasTokenDescription
        case .cardanoInsufficientBalanceToSendToken(let tokenSymbol):
            return Localization.cardanoInsufficientBalanceToSendTokenDescription(tokenSymbol)
        case .notEnoughMana(let current, let max):
            return "You don't have enough MANA for this transaction. Please adjust the transfer amount or wait until the MANA is refilled. Your MANA balance is \(current)/\(max)"
        case .invalidMaxAmount(let validMax):
            return "You can transfer only \(validMax) KOIN due to the MANA limit imposed by the Koinos network"
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
        case .insufficientBalanceForFee(let configuration):
            return .init(iconType: .image(Image(configuration.feeAmountTypeIconName)))
        case .invalidNumber,
             .insufficientBalance,
             .dustRestriction,
             .existentialDeposit,
             .amountExceedMaximumUTXO,
             .insufficientAmountToReserveAtDestination,
             .cardanoCannotBeSentBecauseHasTokens,
             .cardanoInsufficientBalanceToSendToken:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .notEnoughMana, .invalidMaxAmount:
            return .init(iconType: .image(Assets.attention.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .invalidNumber,
             .insufficientBalance,
             .insufficientBalanceForFee,
             .dustRestriction,
             .existentialDeposit,
             .amountExceedMaximumUTXO,
             .insufficientAmountToReserveAtDestination,
             .cardanoCannotBeSentBecauseHasTokens,
             .cardanoInsufficientBalanceToSendToken,
             .notEnoughMana,
             .invalidMaxAmount:
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
        case .insufficientBalanceForFee(let configuration):
            return .openFeeCurrency(currencySymbol: configuration.feeAmountTypeCurrencySymbol)
        case .amountExceedMaximumUTXO(let amount, let amountFormatted, _, _):
            return .reduceAmountTo(amount: amount, amountFormatted: amountFormatted)
        case .existentialDeposit(let amount, let amountFormatted):
            return .leaveAmount(amount: amount, amountFormatted: amountFormatted)
        case .invalidNumber,
             .insufficientBalance,
             .dustRestriction,
             .insufficientAmountToReserveAtDestination,
             .cardanoCannotBeSentBecauseHasTokens,
             .cardanoInsufficientBalanceToSendToken,
             .notEnoughMana,
             .invalidMaxAmount:
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
