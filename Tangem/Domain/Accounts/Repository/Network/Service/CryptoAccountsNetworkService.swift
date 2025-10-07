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
    func getArchivedCryptoAccounts() async throws(CryptoAccountsNetworkServiceError) -> [ArchivedCryptoAccountInfo]
    func save(cryptoAccounts: [StoredCryptoAccount], updateType: CryptoAccountsNetworkServiceUpdateType) async throws(CryptoAccountsNetworkServiceError)
}
