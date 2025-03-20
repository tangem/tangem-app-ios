//
//  TransactionHistoryServiceState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TransactionHistoryServiceState {
    case initial
    case loading
    case failedToLoad(Error)
    case loaded

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }
}
