//
//  TokenItem+SwapRateDisplay.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension TokenItem {
    var isBitcoin: Bool {
        if case .blockchain(let network) = self, case .bitcoin = network.blockchain {
            return true
        }
        return false
    }

    var isEthereum: Bool {
        if case .blockchain(let network) = self, case .ethereum = network.blockchain {
            return true
        }
        return false
    }

    var stablecoinRank: Int? {
        guard let id else { return nil }
        return TokenItem.stablecoinRanking[id]
    }

    var isStablecoin: Bool {
        stablecoinRank != nil
    }

    private static let stablecoinRanking: [String: Int] = [
        "tether": 0, // USDT
        "usd-coin": 1, // USDC
        "ethena-usde": 2, // USDe
        "dai": 3, // DAI
        "usd1-wlfi": 4, // USD1
        "paypal-usd": 5, // PYUSD
        "ripple-usd": 6, // RLUSD
        "global-dollar": 7, // USDG
        "falcon-finance-usd": 8, // USDf
        "usdd": 9, // USDD
    ]
}

enum SwapRateDisplaySide {
    /// Display as `1 fromToken ≈ X toToken`
    case fromIsBase
    /// Display as `1 toToken ≈ X fromToken`
    case toIsBase
}

enum SwapRateDisplaySideResolver {
    static func resolve(from: TokenItem, to: TokenItem) -> SwapRateDisplaySide {
        switch (from.isStablecoin, to.isStablecoin) {
        case (true, true):
            // Stable ↔ Stable: higher-ranked stablecoin (lower rank index) is the base
            let fromRank = from.stablecoinRank ?? .max
            let toRank = to.stablecoinRank ?? .max
            return fromRank <= toRank ? .fromIsBase : .toIsBase
        case (false, true):
            // Coin ↔ Stable: coin is the base
            return .fromIsBase
        case (true, false):
            // Stable ↔ Coin: coin is the base
            return .toIsBase
        case (false, false):
            return resolveCoinToCoin(from: from, to: to)
        }
    }

    private static func resolveCoinToCoin(from: TokenItem, to: TokenItem) -> SwapRateDisplaySide {
        // Exact ETH ↔ BTC: ETH is the base
        if from.isEthereum, to.isBitcoin {
            return .fromIsBase
        }
        if from.isBitcoin, to.isEthereum {
            return .toIsBase
        }

        // Pair contains BTC or ETH: the other coin is the base, BTC/ETH is the rate side
        if from.isBitcoin || from.isEthereum {
            return .toIsBase
        }
        if to.isBitcoin || to.isEthereum {
            return .fromIsBase
        }

        // Default: receive (TO) token is the base
        return .toIsBase
    }
}
