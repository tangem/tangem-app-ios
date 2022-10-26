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

struct TokenItemViewModel: Identifiable, Hashable, Equatable, Comparable {
    var id: Int { hashValue }

    let state: WalletModel.State
    let hasTransactionInProgress: Bool
    let name: String
    let fiatBalance: String
    let balance: String
    let rate: String
    let amountType: Amount.AmountType
    let blockchainNetwork: BlockchainNetwork
    let fiatValue: Decimal
    let isCustom: Bool

    init(
        state: WalletModel.State,
        name: String = "",
        balance: String = "",
        fiatBalance: String = "",
        rate: String = "",
        fiatValue: Decimal = 0,
        blockchainNetwork: BlockchainNetwork,
        amountType: Amount.AmountType,
        hasTransactionInProgress: Bool = false,
        isCustom: Bool
    ) {
        self.state = state
        self.name = name
        self.balance = balance
        self.fiatBalance = fiatBalance
        self.rate = rate
        self.fiatValue = fiatValue
        self.blockchainNetwork = blockchainNetwork
        self.amountType = amountType
        self.hasTransactionInProgress = hasTransactionInProgress
        self.isCustom = isCustom
    }

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
        if state.isBlockchainUnreachable || state == .noDerivation {
            return "wallet_balance_blockchain_unreachable".localized
        }

        if hasTransactionInProgress {
            return "wallet_balance_tx_in_progress".localized
        }

        return rate.isEmpty ? "token_item_no_rate".localized : rate
    }

    var isLoading: Bool {
        state.isLoading // false //
    }

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
    static let `default` = TokenItemViewModel(
        state: .created,
        blockchainNetwork: .init(.bitcoin(testnet: false)),
        amountType: .coin,
        isCustom: false
    )
}

