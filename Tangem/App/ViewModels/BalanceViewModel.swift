//
//  BalanceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceViewModel {
    let hasTransactionInProgress: Bool
    let state: WalletModelState
    let name: String
    let fiatBalance: String
    let balance: String
    let tokenBalanceViewModel: TokenBalanceViewModel?

    /// .truncationMode(.middle) in iOS13 produces glitches with empty string transition
    var balanceFormatted: String {
        balance.isEmpty ? " " : balance
    }
}
