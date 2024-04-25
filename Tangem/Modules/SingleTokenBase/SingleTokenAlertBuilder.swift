//
//  SingleTokenAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.AssetRequirementsCondition

struct SingleTokenAlertBuilder {
    var cantSignLongTransactionAlert: AlertBinder {
        .init(title: Localization.warningLongTransactionTitle, message: Localization.warningLongTransactionMessage)
    }

    var tryAgainLaterAlert: AlertBinder {
        .init(title: "", message: Localization.tokenButtonUnavailabilityGenericDescription)
    }

    func receiveAlert(for requirementsCondition: AssetRequirementsCondition?) -> AlertBinder? {
        switch requirementsCondition {
        case .paidTransaction,
             .paidTransactionWithFee:
            return AlertBinder(title: "", message: Localization.warningReceiveBlockedHederaTokenAssociationRequiredMessage)
        case .none:
            break
        }

        return nil
    }

    func sendAlert(for sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions?) -> AlertBinder? {
        switch sendingRestrictions {
        case .hasPendingTransaction:
            if let message = sendingRestrictions?.description {
                return .init(title: Localization.warningSendBlockedPendingTransactionsTitle, message: message)
            }
        case .cantSignLongTransactions:
            return cantSignLongTransactionAlert
        case .zeroWalletBalance:
            return .init(title: "", message: Localization.tokenButtonUnavailabilityReasonEmptyBalance)
        case .blockchainUnreachable:
            return tryAgainLaterAlert
        case .none, .zeroFeeCurrencyBalance:
            break
        }

        return nil
    }

    func swapAlert(for tokenItem: TokenItem, tokenItemSwapState: TokenItemSwapState, isCustom: Bool) -> AlertBinder? {
        let notSupportedToken = AlertBinder(
            title: "",
            message: Localization.tokenButtonUnavailabilityReasonNotExchangeable(tokenItem.name)
        )
        var alert: AlertBinder?
        switch tokenItemSwapState {
        case .unavailable:
            alert = notSupportedToken
        case .loading, .failedToLoadInfo, .notLoaded:
            alert = tryAgainLaterAlert
        case .available:
            if isCustom {
                alert = notSupportedToken
            }
        }

        return alert
    }

    func fulfillAssetRequirementsAlert(
        for requirementsCondition: AssetRequirementsCondition?,
        feeTokenItem: TokenItem,
        hasFeeCurrency: Bool
    ) -> AlertBinder? {
        switch requirementsCondition {
        case .paidTransaction where !hasFeeCurrency:
            return AlertBinder(
                title: "",
                message: Localization.warningHederaTokenAssociationNotEnoughHbarMessage(feeTokenItem.currencySymbol)
            )
        case .paidTransactionWithFee(let feeAmount) where !hasFeeCurrency:
            assert(
                feeAmount.type == feeTokenItem.amountType,
                "Incorrect fee token item received: expected '\(feeAmount.currencySymbol)', got '\(feeTokenItem.currencySymbol)'"
            )
            return AlertBinder(
                title: "",
                message: Localization.warningHederaTokenAssociationNotEnoughHbarMessage(feeTokenItem.currencySymbol)
            )
        case .paidTransaction,
             .paidTransactionWithFee,
             .none:
            break
        }

        return nil
    }

    func sellUnavailableAlert(for tokenItem: TokenItem) -> AlertBinder {
        .init(title: "", message: Localization.tokenButtonUnavailabilityReasonSellUnavailable(tokenItem.name))
    }

    func buyUnavailableAlert(for tokenItem: TokenItem) -> AlertBinder {
        .init(title: "", message: Localization.tokenButtonUnavailabilityReasonBuyUnavailable(tokenItem.name))
    }
}
