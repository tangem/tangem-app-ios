//
//  CoinsCatalogMapper.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Builds a mapping from contract address to coin from Tangem API v1/coins response.
struct CoinsCatalogMapper {
    /// Builds dictionary contractAddress → coin from v1/coins response.
    func buildContractAddressToCoinMap(from response: CoinsList.Response) -> [String: CoinsList.Coin] {
        response.coins.reduce(into: [:]) { map, coin in
            coin.networks
                .compactMap { $0.contractAddress }
                .forEach { map[$0] = coin }
        }
    }
}
