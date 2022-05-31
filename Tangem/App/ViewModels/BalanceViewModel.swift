//
//  BalanceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceViewModel {
    let isToken: Bool
    let hasTransactionInProgress: Bool
    let state: WalletModel.State
    let name: String
    let fiatBalance: String
    let balance: String
    let secondaryBalance: String
    let secondaryFiatBalance: String
    let secondaryName: String
    
    var balanceFormatted: String { // .truncationMode(.middle) in iOS13 produces glitches with empty string transition
        balance.isEmpty ? " " : balance
    }
}
