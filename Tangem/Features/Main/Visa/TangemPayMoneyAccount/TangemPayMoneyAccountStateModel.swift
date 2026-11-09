//
//  TangemPayMoneyAccountStateModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayMoneyAccountStateModel {
    var balance: Balance
    var transactionHistory: TransactionsListView.State
    var isTrxHistoryReloading = false
}

// MARK: - Balance

extension TangemPayMoneyAccountStateModel {
    enum Balance {
        case loading(cached: String)
        case loaded(String)
        case failed(cached: String)

        var isFailed: Bool {
            switch self {
            case .failed: true
            default: false
            }
        }
    }
}
