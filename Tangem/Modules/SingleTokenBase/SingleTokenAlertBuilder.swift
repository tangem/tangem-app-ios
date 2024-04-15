//
//  SingleTokenAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SingleTokenAlertBuilder {
    var cantSignLongTransactionAlert: AlertBinder {
        .init(title: Localization.warningLongTransactionTitle, message: Localization.warningLongTransactionMessage)
    }

    var tryAgainLaterAlert: AlertBinder {
        .init(title: "", message: Localization.tokenButtonUnavailabilityGenericDescription)
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

    func swapAlert(for tokenItem: TokenItem, tokenItemSwapState: TokenItemSwapState) -> AlertBinder? {
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
            if tokenItem.isCustom {
                alert = notSupportedToken
            }
        }

        return alert
    }
}
