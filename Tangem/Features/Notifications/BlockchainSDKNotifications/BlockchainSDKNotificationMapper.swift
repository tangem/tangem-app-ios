//
//  BlockchainSDKNotificationMapper.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import enum BlockchainSdk.ValidationError
import enum BlockchainSdk.WithdrawalNotification
import enum BlockchainSdk.FeeResourceType
import TangemAssets

struct BlockchainSDKNotificationMapper {
    private let tokenItem: TokenItem
    private var tokenItemSymbol: String { tokenItem.currencySymbol }

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    func mapToValidationErrorEvent(_ validationError: ValidationError) -> ValidationErrorEvent {
        switch validationError {
        case .balanceNotFound, .invalidAmount, .invalidFee:
            return .invalidNumber
        case .amountExceedsBalance, .totalExceedsBalance:
            return .insufficientBalance
        case .feeExceedsBalance(_, _, let isFeeCurrency) where isFeeCurrency:
            // If the fee more than the fee/coin balance and we try to send feeCurrency e.g. coin
            // We have to show just `insufficientBalance` without `openFeeCurrency` button
            return .insufficientBalance
        case .feeExceedsBalance(let fee, let blockchain, _):
            let name: String = switch fee.amount.type {
            case .token(let token): token.name
            default: blockchain.coinDisplayName
            }

            let tokenIconInfo = TokenIconInfoBuilder().build(
                for: fee.amount.type,
                in: blockchain,
                isCustom: false
            )

            return .insufficientBalanceForFee(
                configuration: .init(
                    amountCurrencySymbol: tokenItem.currencySymbol,
                    amountCurrencyBlockchainName: tokenItem.blockchain.displayName,
                    transactionAmountTypeName: tokenItem.name,
                    feeAmountTypeName: name,
                    feeAmountTypeCurrencySymbol: fee.amount.currencySymbol,
                    feeTokenIconInfo: tokenIconInfo,
                    networkName: tokenItem.networkName,
                    currencyButtonTitle: nil,
                    // We set true here because we have to show "Go to \(coin)" button
                    isFeeCurrencyPurchaseAllowed: true
                )
            )
        case .dustAmount(let minimumAmount), .dustChange(let minimumAmount):
            let amountText = "\(minimumAmount.value) \(tokenItemSymbol)"
            return .dustRestriction(minimumAmountFormatted: amountText, minimumChangeFormatted: amountText)
        case .minimumBalance(let minimumBalance, let canLeaveAmount):
            return .existentialDeposit(
                amount: minimumBalance.value,
                amountFormatted: minimumBalance.string(),
                canLeaveAmount: canLeaveAmount
            )
        case .maximumUTXO(let blockchainName, let newAmount, let maxUtxo):
            return .amountExceedMaximumUTXO(amount: newAmount.value, amountFormatted: newAmount.string(), blockchainName: blockchainName, maxUTXO: maxUtxo)
        case .reserve(let amount):
            return .insufficientAmountToReserveAtDestination(minimumAmountFormatted: amount.string())
        case .cardanoHasTokens:
            return .cardanoCannotBeSentBecauseHasTokens
        case .cardanoInsufficientBalanceToSendToken:
            return .cardanoInsufficientBalanceToSendToken(tokenSymbol: tokenItemSymbol)
        case .insufficientFeeResource(.mana, let current, let max):
            return .notEnoughMana(current: current, max: max)
        case .amountExceedsFeeResourceCapacity(.mana, let availableAmount):
            return .manaLimit(availableAmount: availableAmount)
        case .feeExceedsMaxFeeResource:
            return .koinosInsufficientBalanceToSendKoin
        case .minimumRestrictAmount(let restrictAmount):
            return .minimumRestrictAmount(restrictAmountFormatted: restrictAmount.string())
        case .remainingAmountIsLessThanRentExemption(let amount):
            return .remainingAmountIsLessThanRentExemption(amount: amount.description)
        case .sendingAmountIsLessThanRentExemption(let amount):
            return .sendingAmountIsLessThanRentExemption(amount: amount.description)
        case .destinationMemoRequired:
            return .destinationMemoRequired
        case .noTrustlineAtDestination:
            return .noTrustlineAtDestination
        }
    }

    func mapToWithdrawalNotificationEvent(_ notification: WithdrawalNotification) -> WithdrawalNotificationEvent {
        switch notification {
        case .feeIsTooHigh(let reduceAmountBy):
            return .reduceAmountBecauseFeeIsTooHigh(
                amount: reduceAmountBy.value,
                amountFormatted: reduceAmountBy.string(),
                blockchainName: tokenItem.blockchain.displayName
            )
        case .cardanoWillBeSendAlongToken(let amount):
            return .cardanoWillBeSendAlongToken(
                cardanoAmountFormatted: amount.value.description,
                tokenSymbol: tokenItem.currencySymbol
            )
        case .tronWillBeSendTokenFeeDescription:
            return .tronWillBeSendTokenFeeDescription
        }
    }
}
