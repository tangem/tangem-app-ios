//
//  CommonCryptoAccountsNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonCryptoAccountsNetworkService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - CryptoAccountsNetworkService protocol conformance

extension CommonCryptoAccountsNetworkService: CryptoAccountsNetworkService {
    func getCryptoAccounts(for walletId: String) async throws(CryptoAccountsNetworkServiceError) -> [StoredCryptoAccount] {
        // [REDACTED_TODO_COMMENT]
        throw CryptoAccountsNetworkServiceError.underlyingError("Not implemented")
    }

    func save(cryptoAccounts: [StoredCryptoAccount]) async throws(CryptoAccountsNetworkServiceError) {
        // [REDACTED_TODO_COMMENT]
        throw CryptoAccountsNetworkServiceError.underlyingError("Not implemented")
    }
}
