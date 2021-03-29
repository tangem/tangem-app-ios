//
//  TokenBalanceViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TokenBalanceViewModel: Hashable, Identifiable {
    var id: Int { token.hashValue }
    
    let name: String
    let tokenName: String
    let balance: String
    let fiatBalance: String
    let token: Token
    
    init(token: Token, balance: String, fiatBalance: String) {
        self.name = token.name
        self.tokenName = token.symbol
        self.balance = balance
        self.fiatBalance = fiatBalance
        self.token = token
    }
}
