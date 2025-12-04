//
//  ValidationErrorEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import SwiftUI
import TangemAssets

enum ValidationErrorEvent: Hashable {
    // Amount/Fee notifications
    case invalidNumber
    case insufficientBalance
    case insufficientBalanceForFee(configuration: SendingRestrictions.NotEnoughFeeConfiguration)

    // Blockchain specific notifications
    case dustRestriction(minimumAmountFormatted: String, minimumChangeFormatted: String)
    case existentialDeposit(amount: Decimal, amountFormatted: String, canLeaveAmount: Bool)
    case amountExceedMaximumUTXO(amount: Decimal, amountFormatted: String, blockchainName: String, maxUTXO: Int)
    case insufficientAmountToReserveAtDestination(minimumAmountFormatted: String)
    case cardanoCannotBeSentBecauseHasTokens
    case cardanoInsufficientBalanceToSendToken(tokenSymbol: String)

    case notEnoughMana(current: Decimal, max: Decimal)
    case manaLimit(availableAmount: Decimal)
    case koinosInsufficientBalanceToSendKoin

    case minimumRestrictAmount(restrictAmountFormatted: String)
    case remainingAmountIsLessThanRentExemption(amount: String)
    case sendingAmountIsLessThanRentExemption(amount: String)

    case destinationMemoRequired
    case noTrustlineAtDestination
}

extension ValidationErrorEvent {
    var id: Int {
        switch self {
        case .invalidNumber: "invalidNumber".hashValue
        case .insufficientBalance: "insufficientBalance".hashValue
        case .insufficientBalanceForFee: "insufficientBalanceForFee".hashValue
        case .dustRestriction: "dustRestriction".hashValue
        case .existentialDeposit: "existentialDeposit".hashValue
        case .amountExceedMaximumUTXO: "amountExceedMaximumUTXO".hashValue
        case .insufficientAmountToReserveAtDestination: "insufficientAmountToReserveAtDestination".hashValue
        case .cardanoCannotBeSentBecauseHasTokens: "cardanoCannotBeSentBecauseHasTokens".hashValue
        case .cardanoInsufficientBalanceToSendToken: "cardanoInsufficientBalanceToSendToken".hashValue
        case .notEnoughMana: "notEnoughMana".hashValue
        case .manaLimit: "manaLimit".hashValue
        case .koinosInsufficientBalanceToSendKoin: "koinosInsufficientBalanceToSendKoin".hashValue
        case .minimumRestrictAmount: "minimumRestrictAmount".hashValue
        case .remainingAmountIsLessThanRentExemption: "remainingAmountIsLessThanRentExemption".hashValue
        case .sendingAmountIsLessThanRentExemption: "sendingAmountIsLessThanRentExemption".hashValue
        case .destinationMemoRequired: "destinationMemoRequired".hashValue
        case .noTrustlineAtDestination: "noTrustlineAtDestination".hashValue
        }
    }

    var title: NotificationView.Title? {
        switch self {
        case .invalidNumber:
            return .string(Localization.commonError)
        case .insufficientBalance:
            return .string(Localization.sendNotificationExceedBalanceTitle)
        case .insufficientBalanceForFee(let configuration):
            return .string(Localization.warningSendBlockedFundsForFeeTitle(configuration.feeAmountTypeName))
        case .dustRestriction, .remainingAmountIsLessThanRentExemption, .sendingAmountIsLessThanRentExemption:
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
            return .string(Localization.koinosInsufficientManaToSendKoinTitle)
        case .manaLimit:
            return .string(Localization.koinosManaExceedsKoinBalanceTitle)
        case .koinosInsufficientBalanceToSendKoin:
            return .string(Localization.koinosInsufficientBalanceToSendKoinTitle)
        case .minimumRestrictAmount:
            return .string(Localization.sendNotificationInvalidAmountTitle)
        case .destinationMemoRequired:
            return .string(Localization.sendValidationDestinationTagRequiredTitle)
        case .noTrustlineAtDestination:
            return .string(Localization.commonError)
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
        case .existentialDeposit(_, let amountFormatted, _):
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
            return Localization.koinosInsufficientManaToSendKoinDescription(current, max)
        case .manaLimit(let validMax):
            return Localization.koinosManaExceedsKoinBalanceDescription(validMax)
        case .koinosInsufficientBalanceToSendKoin:
            return Localization.koinosInsufficientBalanceToSendKoinDescription
        case .minimumRestrictAmount(let restrictAmountFormatted):
            return Localization.transferNotificationInvalidMinimumTransactionAmountText(restrictAmountFormatted)
        case .remainingAmountIsLessThanRentExemption(let amount):
            return Localization.sendNotificationInvalidAmountRentFee(amount)
        case .sendingAmountIsLessThanRentExemption(let amount):
            return Localization.sendNotificationInvalidAmountRentDestination(amount)
        case .destinationMemoRequired:
            return Localization.sendValidationDestinationTagRequiredDescription
        case .noTrustlineAtDestination:
            return Localization.noTrustlineXlmAsset
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        let hasButton = buttonAction != nil
        if hasButton {
            return .action
        }

        return .secondary
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .insufficientBalanceForFee(let configuration):
            return .init(iconType: .image(configuration.feeAmountTypeIconAsset.image))
        case .invalidNumber,
             .insufficientBalance,
             .dustRestriction,
             .existentialDeposit,
             .amountExceedMaximumUTXO,
             .insufficientAmountToReserveAtDestination,
             .cardanoCannotBeSentBecauseHasTokens,
             .cardanoInsufficientBalanceToSendToken,
             .notEnoughMana,
             .manaLimit,
             .koinosInsufficientBalanceToSendKoin,
             .remainingAmountIsLessThanRentExemption,
             .sendingAmountIsLessThanRentExemption,
             .minimumRestrictAmount,
             .destinationMemoRequired,
             .noTrustlineAtDestination:
            return .init(iconType: .image(Assets.redCircleWarning.image))
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
             .manaLimit,
             .koinosInsufficientBalanceToSendKoin,
             .remainingAmountIsLessThanRentExemption,
             .sendingAmountIsLessThanRentExemption,
             .minimumRestrictAmount,
             .destinationMemoRequired,
             .noTrustlineAtDestination:
            return .critical
        }
    }

    var isDismissable: Bool {
        return false
    }
}

// MARK: Button

extension ValidationErrorEvent {
    var buttonAction: NotificationButtonAction? {
        switch self {
        case .insufficientBalanceForFee(let configuration):
            return .init(.openFeeCurrency(currencySymbol: configuration.feeAmountTypeCurrencySymbol))
        case .amountExceedMaximumUTXO(let amount, let amountFormatted, _, _):
            return .init(.reduceAmountTo(amount: amount, amountFormatted: amountFormatted))
        case .existentialDeposit(let amount, let amountFormatted, let canLeaveAmount):
            return .init(.leaveAmount(amount: amount, amountFormatted: amountFormatted), isDisabled: !canLeaveAmount)
        case .manaLimit(let available):
            return .init(.reduceAmountTo(amount: available, amountFormatted: "\(available)"))
        case .invalidNumber,
             .insufficientBalance,
             .dustRestriction,
             .insufficientAmountToReserveAtDestination,
             .cardanoCannotBeSentBecauseHasTokens,
             .cardanoInsufficientBalanceToSendToken,
             .notEnoughMana,
             .koinosInsufficientBalanceToSendKoin,
             .remainingAmountIsLessThanRentExemption,
             .sendingAmountIsLessThanRentExemption,
             .minimumRestrictAmount,
             .destinationMemoRequired,
             .noTrustlineAtDestination:
            return nil
        }
    }
}
