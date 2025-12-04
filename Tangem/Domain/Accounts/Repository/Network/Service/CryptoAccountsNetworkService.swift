//
//  CryptoAccountsNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletsNetworkService {
    func createWallet(with context: some Encodable) async throws(CryptoAccountsNetworkServiceError)
    func updateWallet(userWalletId: String, context: some Encodable) async throws(CryptoAccountsNetworkServiceError)
}

protocol CryptoAccountsNetworkService {
    @discardableResult
    func getCryptoAccounts(
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo

    @discardableResult
    func saveAccounts(
        from cryptoAccounts: [StoredCryptoAccount],
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo

    func saveTokens(
        from cryptoAccounts: [StoredCryptoAccount],
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError)
}
