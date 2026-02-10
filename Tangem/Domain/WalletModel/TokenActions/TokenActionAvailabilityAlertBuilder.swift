//
//  TokenActionAvailabilityAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder
import enum BlockchainSdk.Blockchain

struct TokenActionAvailabilityAlertBuilder {
    func alert(for sendingRestrictions: SendingRestrictions?) -> AlertBinder? {
        switch sendingRestrictions {
        case .none, .zeroFeeCurrencyBalance:
            return nil
        case .zeroWalletBalance, .noAccount:
            return AlertBinder(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonEmptyBalanceSend
            )
        case .hasOnlyCachedBalance:
            return outOfDateBalanceAlert
        case .cantSignLongTransactions:
            return cantSignLongTransactionAlert
        case .hasPendingWithdrawOrder:
            return AlertBinder(
                title: Localization.tangempayCardDetailsWithdrawInProgressTitle,
                message: Localization.tangempayCardDetailsWithdrawInProgressDescription
            )
        case .hasPendingTransaction(let blockchainDisplayName):
            return AlertBinder(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonPendingTransactionSend(blockchainDisplayName)
            )
        case .blockchainUnreachable, .blockchainLoading:
            return tryAgainLaterAlert
        case .oldCard:
            return oldCardAlert
        }
    }

    func alert(for status: TokenActionAvailabilityProvider.SendActionAvailabilityStatus) -> AlertBinder? {
        switch status {
        case .available:
            return nil
        case .hasPendingTransaction(let blockchainDisplayName):
            return .init(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonPendingTransactionSend(blockchainDisplayName)
            )
        case .cantSignLongTransactions:
            return cantSignLongTransactionAlert
        case .hasOnlyCachedBalance:
            return outOfDateBalanceAlert
        case .zeroWalletBalance, .noAccount:
            return .init(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonEmptyBalanceSend
            )
        case .blockchainUnreachable, .blockchainLoading:
            return tryAgainLaterAlert
        case .oldCard:
            return oldCardAlert
        case .yieldModuleApproveNeeded:
            return .init(title: "", message: Localization.tokenButtonUnavailabilityReasonYieldSupplyApproval)
        }
    }

    func alert(for status: TokenActionAvailabilityProvider.SwapActionAvailabilityStatus) -> AlertBinder? {
        switch status {
        case .available, .hidden:
            return nil
        case .blockchainUnreachable, .blockchainLoading:
            return tryAgainLaterAlert
        case .cantSignLongTransactions:
            return cantSignLongTransactionAlert
        case .customToken:
            return .init(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonCustomToken
            )
        case .expressLoading:
            return expressLoadingAlert
        case .expressNotLoaded:
            return tryAgainLaterAlert
        case .expressUnreachable:
            return tryAgainLaterAlert
        case .hasOnlyCachedBalance:
            return outOfDateBalanceAlert
        case .unavailable(let tokenName):
            return .init(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonNotExchangeable(tokenName)
            )
        case .missingAssetRequirement:
            return .init(title: "", message: Localization.warningReceiveBlockedTokenTrustlineRequiredMessage)
        case .yieldModuleApproveNeeded:
            return .init(title: "", message: Localization.tokenButtonUnavailabilityReasonYieldSupplyApproval)
        }
    }

    func alert(for status: TokenActionAvailabilityProvider.BuyActionAvailabilityStatus) -> AlertBinder? {
        switch status {
        case .available:
            return nil
        case .unavailable(let tokenName):
            return .init(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonBuyUnavailable(tokenName)
            )
        case .expressUnreachable:
            return tryAgainLaterAlert
        case .expressLoading:
            return expressLoadingAlert
        case .expressNotLoaded:
            return tryAgainLaterAlert
        case .demo(disabledLocalizedReason: let disabledLocalizedReason):
            return AlertBuilder.makeDemoAlert(disabledLocalizedReason)
        case .missingAssetRequirement:
            return .init(title: "", message: Localization.warningReceiveBlockedTokenTrustlineRequiredMessage)
        }
    }

    func alert(for status: TokenActionAvailabilityProvider.SellActionAvailabilityStatus) -> AlertBinder? {
        switch status {
        case .available:
            return nil
        case .unavailable(let tokenName):
            return .init(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonSellUnavailable(tokenName)
            )
        case .zeroWalletBalance, .noAccount:
            return .init(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonEmptyBalanceSell
            )
        case .cantSignLongTransactions:
            return cantSignLongTransactionAlert
        case .hasPendingTransaction(let blockchainDisplayName):
            return .init(
                title: "",
                message: Localization.tokenButtonUnavailabilityReasonPendingTransactionSell(blockchainDisplayName)
            )
        case .blockchainUnreachable, .blockchainLoading:
            return tryAgainLaterAlert
        case .oldCard:
            return oldCardAlert
        case .hasOnlyCachedBalance:
            return outOfDateBalanceAlert
        case .demo(let disabledLocalizedReason):
            return AlertBuilder.makeDemoAlert(disabledLocalizedReason)
        case .yieldModuleApproveNeeded:
            return .init(title: "", message: Localization.tokenButtonUnavailabilityReasonYieldSupplyApproval)
        }
    }

    func alert(for status: TokenActionAvailabilityProvider.ReceiveActionAvailabilityStatus, blockchain: Blockchain) -> AlertBinder? {
        switch status {
        case .available:
            return nil

        case .assetRequirement:
            switch blockchain {
            case .xrp, .stellar:
                return .init(title: "", message: Localization.warningReceiveBlockedTokenTrustlineRequiredMessage)
            case .hedera:
                return .init(title: "", message: Localization.warningReceiveBlockedHederaTokenAssociationRequiredMessage)
            default:
                return nil
            }
        }
    }
}

// MARK: - Private

extension TokenActionAvailabilityAlertBuilder {
    private var cantSignLongTransactionAlert: AlertBinder {
        .init(title: Localization.warningLongTransactionTitle, message: Localization.warningLongTransactionMessage)
    }

    private var tryAgainLaterAlert: AlertBinder {
        .init(title: "", message: Localization.tokenButtonUnavailabilityGenericDescription)
    }

    private var outOfDateBalanceAlert: AlertBinder {
        .init(title: "", message: Localization.tokenButtonUnavailabilityReasonOutOfDateBalance)
    }

    private var oldCardAlert: AlertBinder {
        .init(title: "", message: Localization.warningOldCardMessage)
    }

    private var expressLoadingAlert: AlertBinder {
        .init(
            title: "",
            message: Localization.tokenButtonUnavailabilityReasonLoading
        )
    }
}
