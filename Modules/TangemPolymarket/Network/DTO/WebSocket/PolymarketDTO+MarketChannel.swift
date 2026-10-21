//
//  PolymarketDTO+MarketChannel.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    enum MarketChannelPayload: Decodable {
        case single(MarketChannelMessage)
        case batch([MarketChannelMessage])

        var messages: [MarketChannelMessage] {
            switch self {
            case .single(let message):
                [message]
            case .batch(let messages):
                messages
            }
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()

            do {
                self = .batch(try container.decode([MarketChannelMessage].self))
            } catch DecodingError.typeMismatch(_, let context) where context.codingPath.isEmpty {
                self = .single(try container.decode(MarketChannelMessage.self))
            }
        }
    }

    struct MarketChannelMessage: Decodable {
        let eventType: String?
        let assetId: String?
        let bids: [MarketChannelLevel]?
        let asks: [MarketChannelLevel]?
        let priceChanges: [MarketChannelPriceChange]?
        let price: String?
        let timestamp: String?
    }

    struct MarketChannelLevel: Decodable {
        let price: String
    }

    struct MarketChannelPriceChange: Decodable {
        let assetId: String
        let bestBid: String?
        let bestAsk: String?
    }

    struct MarketChannelSubscription: Encodable {
        let assetsIds: [String]
        let type = "market"
    }

    struct MarketChannelSubscriptionUpdate: Encodable {
        let operation: Operation
        let assetsIds: [String]
    }
}

extension PolymarketDTO.MarketChannelSubscriptionUpdate {
    enum Operation: String, Encodable {
        case subscribe
        case unsubscribe
    }
}
