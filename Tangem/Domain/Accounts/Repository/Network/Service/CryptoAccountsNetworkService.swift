//
//  CryptoAccountsNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol CryptoAccountsNetworkService {
    func getCryptoAccounts() async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo
    @discardableResult
    func saveAccounts(from cryptoAccounts: [StoredCryptoAccount]) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo
    func saveTokens(from cryptoAccounts: [StoredCryptoAccount]) async throws(CryptoAccountsNetworkServiceError)
}
