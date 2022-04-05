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
    let hasTransactionInProgress: Bool
    let name: String
    let fiatBalance: String
    let balance: String
    let rate: String
    let amountType: Amount.AmountType
    let blockchainNetwork: BlockchainNetwork
    let fiatValue: Decimal
    
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
    
    static let `default` = TokenItemViewModel(state: .created, hasTransactionInProgress: false, name: "", fiatBalance: "", balance: "", rate: "", amountType: .coin, blockchainNetwork: .init(.bitcoin(testnet: false)), fiatValue: 0)
    
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
         hasTransactionInProgress: Bool) {
        self.hasTransactionInProgress = hasTransactionInProgress
        state = balanceViewModel.state
        name = balanceViewModel.name
        if name == "" {
            
        }
        balance = balanceViewModel.balance
        fiatBalance = balanceViewModel.fiatBalance
        self.rate = rate
        self.blockchainNetwork = blockchainNetwork
        self.amountType = .coin
        self.fiatValue = fiatValue
    }
    
    init(from balanceViewModel: BalanceViewModel,
         tokenBalanceViewModel: TokenBalanceViewModel,
         rate: String,
         fiatValue: Decimal,
         blockchainNetwork: BlockchainNetwork,
         hasTransactionInProgress: Bool) {
        self.hasTransactionInProgress = hasTransactionInProgress
        state = balanceViewModel.state
        name = tokenBalanceViewModel.name
        balance = tokenBalanceViewModel.balance
        fiatBalance = tokenBalanceViewModel.fiatBalance
        self.rate = rate
        self.blockchainNetwork = blockchainNetwork
        self.amountType = .token(value: tokenBalanceViewModel.token)
        self.fiatValue = fiatValue
    }
}

