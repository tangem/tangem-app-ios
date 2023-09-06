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
    // [REDACTED_TODO_COMMENT]
    case unableToCoverFee(tokenItem: TokenItem)
    case networkUnreachable
    case rentFee(rentMessage: String)
    case noAccount(message: String, isNoteWallet: Bool, currencySymbol: String?)
    case existentialDepositWarning(message: String)
    case longTransaction(message: String)
    case hasPendingTransactions(message: String)
    case notEnoughtFeeForTokenTx(message: String)

    static func event(for reason: WalletModel.SendBlockedReason) -> TokenNotificationEvent {
        let message = reason.description
        switch reason {
        case .cantSignLongTransactions:
            return .longTransaction(message: message)
        case .hasPendingCoinTx:
            return .hasPendingTransactions(message: message)
        case .notEnoughtFeeForTokenTx:
            return .notEnoughtFeeForTokenTx(message: message)
        }
    }

    var buttonAction: NotificationButtonActionType? {
        switch self {
        case .unableToCoverFee:
            return nil
        case .noAccount(_, _, let currencySymbol):
            return .buyCrypto(currencySymbol: currencySymbol)
        case .networkUnreachable, .rentFee, .existentialDepositWarning, .longTransaction, .hasPendingTransactions, .notEnoughtFeeForTokenTx:
            return nil
        }
    }
}

extension TokenNotificationEvent: NotificationEvent {
    private var defaultTitle: String {
        Localization.commonWarning
    }

    var title: String {
        switch self {
        case .unableToCoverFee(let tokenItem):
            return "Unable to cover \(tokenItem.blockchain.displayName) fee"
        case .networkUnreachable:
            return "Network is uncreachable"
        case .rentFee:
            return "Network rent fee"
        case .noAccount(_, let isNoteWallet, _):
            if isNoteWallet {
                return "Note top up"
            }

            return Localization.walletErrorNoAccount
        case .existentialDepositWarning:
            return defaultTitle
        case .longTransaction:
            return defaultTitle
        case .hasPendingTransactions:
            return Localization.walletBalanceTxInProgress
        case .notEnoughtFeeForTokenTx:
            return defaultTitle
        }
    }

    var description: String? {
        switch self {
        case .unableToCoverFee(let tokenItem):
            guard let token = tokenItem.token else {
                return "Top up right here"
            }

            let blockchain = tokenItem.blockchain
            return Localization.tokenDetailsSendBlockedFeeFormat(
                token.name,
                blockchain.displayName,
                token.name,
                blockchain.displayName,
                blockchain.currencySymbol
            )
        case .networkUnreachable:
            return "Network currently is unreachable. Please try again later."
        case .rentFee(let message):
            return message
        case .noAccount(let message, _, _):
            return message
        case .existentialDepositWarning(let message):
            return message
        case .longTransaction(let message):
            return message
        case .hasPendingTransactions(let message):
            return message
        case .notEnoughtFeeForTokenTx(let message):
            return message
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .unableToCoverFee(let tokenItem):
            if tokenItem.token == nil {
                return .white
            }

            return .gray
        case .networkUnreachable, .rentFee, .longTransaction, .existentialDepositWarning, .hasPendingTransactions, .notEnoughtFeeForTokenTx:
            return .gray
        case .noAccount(_, let isNoteWallet, _):
            return isNoteWallet ? .white : .gray
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .unableToCoverFee(let tokenItem):
            return .init(image: Image(name: tokenItem.blockchain.iconNameFilled))
        case .networkUnreachable, .rentFee, .longTransaction, .noAccount, .hasPendingTransactions, .notEnoughtFeeForTokenTx:
            return .init(image: Assets.attention.image)
        case .existentialDepositWarning:
            return .init(image: Assets.attentionRed.image)
        }
    }

    var isDismissable: Bool {
        switch self {
        case .rentFee, .noAccount:
            return true
        case .networkUnreachable, .unableToCoverFee, .longTransaction, .existentialDepositWarning, .hasPendingTransactions, .notEnoughtFeeForTokenTx:
            return false
        }
    }
}
