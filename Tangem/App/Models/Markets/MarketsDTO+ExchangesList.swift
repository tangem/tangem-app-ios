//
//  MarketsDTO+ExchangesList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension MarketsDTO {
    enum ExchangesList {}

    typealias ExchangesRequest = MarketsDTO.ExchangesList.Request
    typealias ExchangesResponse = MarketsDTO.ExchangesList.Response
    typealias ExchangesListItemInfo = MarketsDTO.ExchangesList.ItemInfo
}

extension MarketsDTO.ExchangesList {
    struct Request: Encodable {
        let tokenId: String
    }

    struct Response: Decodable {
        let exchanges: [ItemInfo]
    }

    struct ItemInfo: Decodable {
        let exchangeId: String
        let name: String
        let image: String?
        let centralized: Bool
        let volumeUsd: Decimal
        let trustScore: MarketsExchangeTrustScore?
    }
}
