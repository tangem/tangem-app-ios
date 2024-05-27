//
//  DummyMarketTokenModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct DummyMarketTokenModelFactory {
    // [REDACTED_TODO_COMMENT]
    func list() -> [MarketTokenModel] {
        [
            MarketTokenModel(
                id: "bitcoin",
                name: "Bitcoin",
                symbol: "BTC",
                marketCup: "1T",
                marketRaiting: "1"
            ),
            MarketTokenModel(
                id: "ethereum",
                name: "Ethereum",
                symbol: "ETH",
                marketCup: "100B",
                marketRaiting: "2"
            ),
            MarketTokenModel(
                id: "solana",
                name: "Solana",
                symbol: "SOL",
                marketCup: "10M",
                marketRaiting: "3"
            ),
        ]
    }
}
