//
//  CoinsCatalogMapper.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Builds a mapping from contract address (lowercased) to coin catalog id from Tangem API v1/coins response.
struct CoinsCatalogMapper {
    /// Builds dictionary contractAddress (lowercased) → coin.id from v1/coins response.
    /// Used for matching Moralis token_address with catalog currencyId.
    func buildContractAddressToCoinIdMap(from response: CoinsList.Response) -> [String: String] {
        response.coins.reduce(into: [:]) { map, coin in
            coin.networks
                .compactMap { $0.contractAddress }
                .forEach { map[$0.lowercased()] = coin.id }
        }
    }
}
