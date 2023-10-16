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
    case networkUnreachable
    case someNetworksUnreachable
    case rentFee(rentMessage: String)
    case noAccount(message: String, isNoteWallet: Bool)
    case existentialDepositWarning(message: String)
    case longTransaction(message: String)
    case hasPendingTransactions(message: String)
    case notEnoughtFeeForTokenTx(tokenName: String, blockchainCurrencySymbol: String, blockchainName: String, blockchainIconName: String)

    static func event(for reason: WalletModel.SendBlockedReason) -> TokenNotificationEvent {
        let message = reason.description
        switch reason {
        case .cantSignLongTransactions:
            return .longTransaction(message: message)
        case .hasPendingCoinTx:
            return .hasPendingTransactions(message: message)
        case .notEnoughtFeeForTokenTx(let tokenName, let networkName, let coinSymbol, let chainIconName):
            return .notEnoughtFeeForTokenTx(tokenName: tokenName, blockchainCurrencySymbol: coinSymbol, blockchainName: networkName, blockchainIconName: chainIconName)
        }
    }

    var buttonAction: NotificationButtonActionType? {
        switch self {
        // One notification with button action will be added later
        case .networkUnreachable, .someNetworksUnreachable, .rentFee, .existentialDepositWarning, .longTransaction, .hasPendingTransactions, .noAccount:
            return nil
        case .notEnoughtFeeForTokenTx(_, let blockchainCurrencySymbol, _, _):
            return .openNetworkCurrency(currencySymbol: blockchainCurrencySymbol)
        }
    }
}

extension TokenNotificationEvent: NotificationEvent {
    private var defaultTitle: String {
        Localization.commonWarning
    }

    var title: String {
        switch self {
        case .networkUnreachable:
            // [REDACTED_TODO_COMMENT]
            return "Network is uncreachable"
        case .someNetworksUnreachable:
            // [REDACTED_TODO_COMMENT]
            return "Some networks are unreachable"
        case .rentFee:
            // [REDACTED_TODO_COMMENT]
            return "Network rent fee"
        case .noAccount(_, let isNoteWallet):
            if isNoteWallet {
                // [REDACTED_TODO_COMMENT]
                return "Note top up"
            }

            return Localization.walletErrorNoAccount
        case .existentialDepositWarning:
            return defaultTitle
        case .longTransaction:
            return defaultTitle
        case .hasPendingTransactions:
            return Localization.walletBalanceTxInProgress
        case .notEnoughtFeeForTokenTx(_, _, let blockchainName, _):
            return Localization.notificationTitleNotEnoughFunds(blockchainName)
        }
    }

    var description: String? {
        switch self {
        case .networkUnreachable:
            // [REDACTED_TODO_COMMENT]
            return "Network currently is unreachable. Please try again later."
        case .someNetworksUnreachable:
            // [REDACTED_TODO_COMMENT]
            return "Some networks currently are unreachable. Please try again later."
        case .rentFee(let message):
            return message
        case .noAccount(let message, _):
            return message
        case .existentialDepositWarning(let message):
            return message
        case .longTransaction(let message):
            return message
        case .hasPendingTransactions(let message):
            return message
        case .notEnoughtFeeForTokenTx(let tokenName, let blockchainCurrencySymbol, let blockchainName, _):
            return Localization.notificationSubtitleNotEnoughFunds(tokenName, blockchainName, blockchainCurrencySymbol)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkUnreachable, .someNetworksUnreachable, .rentFee, .longTransaction, .existentialDepositWarning, .hasPendingTransactions, .noAccount:
            return .gray
        // One white notification will be added later
        case .notEnoughtFeeForTokenTx:
            return .white
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkUnreachable, .someNetworksUnreachable, .rentFee, .longTransaction, .noAccount, .hasPendingTransactions:
            return .init(image: Assets.attention.image)
        case .existentialDepositWarning:
            return .init(image: Assets.redCircleWarning.image)
        case .notEnoughtFeeForTokenTx(_, _, _, let blockchainIconName):
            return .init(image: Image(blockchainIconName))
        }
    }

    var isDismissable: Bool {
        switch self {
        case .rentFee:
            return true
        case .networkUnreachable, .someNetworksUnreachable, .longTransaction, .existentialDepositWarning, .hasPendingTransactions, .notEnoughtFeeForTokenTx, .noAccount:
            return false
        }
    }
}
