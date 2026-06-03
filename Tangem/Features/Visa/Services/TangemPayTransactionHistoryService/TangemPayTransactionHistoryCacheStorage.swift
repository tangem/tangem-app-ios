//
//  TangemPayTransactionHistoryCacheStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayTransactionHistoryCacheStorage {
    func cachedTransactions(customerWalletId: String) -> [TangemPayTransactionRecord]?
    func saveCachedTransactions(_ transactions: [TangemPayTransactionRecord], customerWalletId: String)
}
