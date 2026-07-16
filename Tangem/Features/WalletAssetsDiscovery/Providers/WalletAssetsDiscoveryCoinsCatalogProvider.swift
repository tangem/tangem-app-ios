//
//  WalletAssetsDiscoveryCoinsCatalogProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol InitialWalletTokenSyncCoinsCatalogProvider {
    func fetchContractAddressToCoinMap(
        contractAddresses: [String],
        blockchain: Blockchain
    ) async -> [String: CoinsList.Coin]
}

struct CommonInitialWalletTokenSyncCoinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider {
    private let tangemApiService: TangemApiService
    private let coinMapper = CoinsCatalogMapper()

    init(tangemApiService: TangemApiService) {
        self.tangemApiService = tangemApiService
    }

    func fetchContractAddressToCoinMap(
        contractAddresses: [String],
        blockchain: Blockchain
    ) async -> [String: CoinsList.Coin] {
        guard let response = await loadCoinsResponse(contractAddresses: contractAddresses, blockchain: blockchain) else {
            return [:]
        }
        let contractAddressToCoin = coinMapper.buildContractAddressToCoinMap(from: response)
        return contractAddressToCoin
    }

    private func loadCoinsResponse(contractAddresses: [String], blockchain: Blockchain) async -> CoinsList.Response? {
        guard contractAddresses.isNotEmpty else {
            return nil
        }

        do {
            let request = CoinsList.Request(
                supportedBlockchains: [blockchain],
                contractAddresses: contractAddresses,
                limit: contractAddresses.count,
                active: true
            )
            return try await tangemApiService.loadCoins(requestModel: request)
        } catch {
            AssetsDiscoveryLogger.debug("Coins catalog lookup failed: \(error)")
            return nil
        }
    }
}
