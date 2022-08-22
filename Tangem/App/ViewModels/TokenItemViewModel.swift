//
//  TokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
import SwiftUI

struct TokenItemViewModel: Identifiable, Equatable, Comparable {
    let id = UUID()
    let state: WalletModel.State
    let displayState: WalletModel.DisplayState
    let hasTransactionInProgress: Bool
    let name: String
    let fiatBalance: String
    let balance: String
    let rate: String
    let amountType: Amount.AmountType
    let blockchainNetwork: BlockchainNetwork
    let fiatValue: Decimal
    let isCustom: Bool

    var currencySymbol: String {
        if amountType == .coin {
            return blockchainNetwork.blockchain.currencySymbol
        } else if let token = amountType.token {
            return token.symbol
        }
        return ""
    }

    var isTestnet: Bool {
        blockchainNetwork.blockchain.isTestnet
    }

    var displayBalanceText: String {
        if state.failureDescription != nil {
            return "—"
        }
        return balance.isEmpty ? Decimal(0).currencyFormatted(code: currencySymbol) : balance
    }

    var displayFiatBalanceText: String {
        if rate.isEmpty {
            return "—"
        }

        if state.isNoAccount {
            return fiatBalance
        }

        return state.failureDescription != nil ? "—" : fiatBalance
    }

    var displayRateText: String {
        if state.isBlockchainUnreachable {
            return "wallet_balance_blockchain_unreachable".localized
        }

        if hasTransactionInProgress {
            return  "wallet_balance_tx_in_progress".localized
        }

        return rate.isEmpty ? "token_item_no_rate".localized : rate
    }

//    [REDACTED_TODO_COMMENT]
    var isLoading: Bool {
        return (displayState == .busy || balance.isEmpty) && !state.isBlockchainUnreachable && !state.isNoAccount
    }

    static let `default` = TokenItemViewModel(state: .created, displayState: .busy, hasTransactionInProgress: false, name: "", fiatBalance: "", balance: "", rate: "", amountType: .coin, blockchainNetwork: .init(.bitcoin(testnet: false)), fiatValue: 0, isCustom: false)

    static func < (lhs: TokenItemViewModel, rhs: TokenItemViewModel) -> Bool {
        if lhs.fiatValue == 0 && rhs.fiatValue == 0 {
            return lhs.name < rhs.name
        }

        return lhs.fiatValue > rhs.fiatValue
    }

    static func == (lhs: TokenItemViewModel, rhs: TokenItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension TokenItemViewModel {
    init(from balanceViewModel: BalanceViewModel, rate: String, fiatValue: Decimal, blockchainNetwork: BlockchainNetwork,
         hasTransactionInProgress: Bool, isCustom: Bool, displayState: WalletModel.DisplayState) {
        self.hasTransactionInProgress = hasTransactionInProgress
        state = balanceViewModel.state
        self.displayState = displayState
        name = balanceViewModel.name
        if name == "" {

        }
        balance = balanceViewModel.balance
        fiatBalance = balanceViewModel.fiatBalance
        self.rate = rate
        self.blockchainNetwork = blockchainNetwork
        self.amountType = .coin
        self.fiatValue = fiatValue
        self.isCustom = isCustom
    }

    init(from balanceViewModel: BalanceViewModel,
         tokenBalanceViewModel: TokenBalanceViewModel,
         rate: String,
         fiatValue: Decimal,
         blockchainNetwork: BlockchainNetwork,
         hasTransactionInProgress: Bool,
         isCustom: Bool,
         displayState: WalletModel.DisplayState) {
        self.hasTransactionInProgress = hasTransactionInProgress
        state = balanceViewModel.state
        self.displayState = displayState
        name = tokenBalanceViewModel.name
        balance = tokenBalanceViewModel.balance
        fiatBalance = tokenBalanceViewModel.fiatBalance
        self.rate = rate
        self.blockchainNetwork = blockchainNetwork
        self.amountType = .token(value: tokenBalanceViewModel.token)
        self.fiatValue = fiatValue
        self.isCustom = isCustom
    }
}

