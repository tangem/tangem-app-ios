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
    let displayState: WalletModel.DisplayState
    let name: String
    let fiatBalance: String
    let balance: String
    let secondaryBalance: String
    let secondaryFiatBalance: String
    let secondaryName: String
    
    // .truncationMode(.middle) in iOS13 produces glitches with empty string transition
    var balanceFormatted: String {
        balance.isEmpty ? " " : balance
    }
}
