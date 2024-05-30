//
//  MarketDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketDTO {
    enum General {}
}

extension MarketDTO.General {
    struct Request: Encodable {
        let currency: String
        let offset: Int
        let limit: Int
        let interval: MarketPriceIntervalType
        let order: MarketListOrderType
        let generalCoins: Bool
        let search: String?

        init(
            currency: String,
            offset: Int = 0,
            limit: Int = 20,
            interval: MarketPriceIntervalType,
            order: MarketListOrderType,
            generalCoins: Bool = false,
            search: String?
        ) {
            self.currency = currency
            self.offset = offset
            self.limit = limit
            self.interval = interval
            self.order = order
            self.generalCoins = generalCoins
            self.search = search
        }

        // MARK: - Helper

        var parameters: [String: Any] {
            var params: [String: Any] = [
                "currency": currency,
                "offset": offset,
                "limit": limit,
                "interval": interval.rawValue,
                "order": order.rawValue,
                "general_coins": generalCoins,
            ]

            if let search {
                params["search"] = search
            }

            return params
        }
    }

    struct Response: Decodable {
        let tokens: [MarketTokenModel]
    }
}
