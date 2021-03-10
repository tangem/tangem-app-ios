//
//  TokenItemViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
import SwiftUI

struct TokenItemViewModel: Identifiable {
    var id = UUID()
    let state: WalletModel.State
    let hasTransactionInProgress: Bool
    let name: String
    let fiatBalance: String
    let balance: String
    let rate: String
    var amountType: Amount.AmountType = .coin
    let blockchain: Blockchain
    
    var currencySymbol: String {
        if amountType == .coin {
            return blockchain.currencySymbol
        } else if let token = amountType.token {
            return token.symbol
        }
        return ""
    }
    
    var tokenItem: TokenItem {
        if case let .token(token) = amountType {
            return .token(token)
        }
        
        return .blockchain(blockchain)
    }
    
    static let `default` = TokenItemViewModel(id: UUID(), state: .created, hasTransactionInProgress: false, name: "", fiatBalance: "", balance: "", rate: "", amountType: .coin, blockchain: .bitcoin(testnet: false))
}

extension TokenItemViewModel {
    init(from balanceViewModel: BalanceViewModel, rate: String, blockchain: Blockchain) {
        hasTransactionInProgress = balanceViewModel.hasTransactionInProgress
        state = balanceViewModel.state
        name = balanceViewModel.name
        if name == "" {
            
        }
        balance = balanceViewModel.balance
        fiatBalance = balanceViewModel.fiatBalance
        self.rate = rate
        self.blockchain = blockchain
        self.amountType = .coin
    }
    
    init(from balanceViewModel: BalanceViewModel,
         tokenBalanceViewModel: TokenBalanceViewModel,
         rate: String,
         blockchain: Blockchain) {
        hasTransactionInProgress = balanceViewModel.hasTransactionInProgress
        state = balanceViewModel.state
        name = tokenBalanceViewModel.name
        balance = tokenBalanceViewModel.balance
        fiatBalance = tokenBalanceViewModel.fiatBalance
        self.rate = rate
        self.blockchain = blockchain
        self.amountType = .token(value: tokenBalanceViewModel.token)
    }
}

