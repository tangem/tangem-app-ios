//
//  CryptoAccountsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
protocol CryptoAccountsService {
    // [REDACTED_TODO_COMMENT]
    func getCryptoAccounts(for walletId: String) async throws(CryptoAccountsServiceError) -> [StoredCryptoAccount]

    // [REDACTED_TODO_COMMENT]
    func save(cryptoAccounts: [StoredCryptoAccount]) async throws(CryptoAccountsServiceError)
}
