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
                active: true,
                imageURL: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "1",
                marketCup: "$1.259 T"
            ),
            MarketTokenModel(
                id: "ethereum",
                name: "Ethereum",
                symbol: "ETH",
                active: true,
                imageURL: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "2",
                marketCup: "$382.744 B "
            ),
            MarketTokenModel(
                id: "tether",
                name: "Tether",
                symbol: "USDT",
                active: true,
                imageURL: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "3",
                marketCup: "$111.436 B"
            ),
            MarketTokenModel(
                id: "binance",
                name: "Binance",
                symbol: "BNB",
                active: true,
                imageURL: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "4",
                marketCup: "$94.244 B"
            ),
            MarketTokenModel(
                id: "polygon",
                name: "Polygon",
                symbol: "MATIC",
                active: true,
                imageURL: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "5",
                marketCup: "$21.690 B"
            ),
        ]
    }
}
