//
//  CommonCryptoAccountsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonCryptoAccountsService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - CryptoAccountsService protocol conformance

extension CommonCryptoAccountsService: CryptoAccountsService {
    func getCryptoAccounts(for walletId: String) async throws(CryptoAccountsServiceError) -> [StoredCryptoAccount] {
        // [REDACTED_TODO_COMMENT]
        throw CryptoAccountsServiceError.underlyingError("Not implemented")
    }

    func save(cryptoAccounts: [StoredCryptoAccount]) async throws(CryptoAccountsServiceError) {
        // [REDACTED_TODO_COMMENT]
        throw CryptoAccountsServiceError.underlyingError("Not implemented")
    }
}
