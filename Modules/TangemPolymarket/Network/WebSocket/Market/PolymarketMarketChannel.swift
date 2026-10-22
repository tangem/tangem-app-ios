//
//  PolymarketMarketChannel.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemWebSocket

struct PolymarketMarketChannel: PolymarketWebSocketChannel, PolymarketWebSocketSubscribing {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    var url: URL {
        PolymarketHost.marketChannel
    }

    var keepalive: PolymarketWebSocketConnectionManager.Keepalive {
        .textPing(.text(Constants.ping), interval: Constants.pingInterval)
    }

    var subscribing: (any PolymarketWebSocketSubscribing<String>)? {
        self
    }

    func subscribeMessage(for topics: Set<String>, isFirstOnConnection: Bool) throws -> WebSocketMessage {
        let assetsIds = topics.sorted()

        guard isFirstOnConnection else {
            return try encode(PolymarketDTO.MarketChannelSubscriptionUpdate(operation: .subscribe, assetsIds: assetsIds))
        }

        return try encode(PolymarketDTO.MarketChannelSubscription(assetsIds: assetsIds))
    }

    func unsubscribeMessage(for topics: Set<String>) throws -> WebSocketMessage {
        try encode(PolymarketDTO.MarketChannelSubscriptionUpdate(operation: .unsubscribe, assetsIds: topics.sorted()))
    }

    func updates(from message: WebSocketMessage) throws -> [Update] {
        guard case .text(let text) = message, !text.isEmpty, text != Constants.pong else {
            return []
        }

        return try decoder.decode(PolymarketDTO.MarketChannelPayload.self, from: Data(text.utf8)).messages.flatMap(updates(fromDTO:))
    }

    func topic(of update: Update) -> String {
        switch update {
        case .bestPrices(let assetId, _, _, _): assetId
        case .lastTrade(let assetId, _, _): assetId
        }
    }

    func value(applying update: Update, to previous: PolymarketOutcomeQuote?) -> PolymarketOutcomeQuote {
        switch update {
        case .bestPrices(let assetId, let bestBid, let bestAsk, let updatedAt):
            PolymarketOutcomeQuote(
                assetId: assetId,
                bestBid: bestBid,
                bestAsk: bestAsk,
                lastTradePrice: previous?.lastTradePrice,
                updatedAt: updatedAt
            )
        case .lastTrade(let assetId, let price, let updatedAt):
            PolymarketOutcomeQuote(
                assetId: assetId,
                bestBid: previous?.bestBid,
                bestAsk: previous?.bestAsk,
                lastTradePrice: price,
                updatedAt: updatedAt
            )
        }
    }
}

// MARK: - Update

extension PolymarketMarketChannel {
    enum Update: Equatable, Sendable {
        case bestPrices(assetId: String, bestBid: Decimal?, bestAsk: Decimal?, updatedAt: Date?)
        case lastTrade(assetId: String, price: Decimal, updatedAt: Date?)
    }
}

// MARK: - Private

private extension PolymarketMarketChannel {
    func encode(_ value: some Encodable) throws -> WebSocketMessage {
        .text(String(decoding: try encoder.encode(value), as: UTF8.self))
    }

    func updates(fromDTO message: PolymarketDTO.MarketChannelMessage) -> [Update] {
        let updatedAt = date(fromMilliseconds: message.timestamp)

        switch message.eventType {
        case Constants.bookEventType:
            guard let assetId = message.assetId, let bids = message.bids, let asks = message.asks else {
                return []
            }

            return [
                .bestPrices(
                    assetId: assetId,
                    bestBid: bids.compactMap { Decimal(stringValue: $0.price) }.max(),
                    bestAsk: asks.compactMap { Decimal(stringValue: $0.price) }.min(),
                    updatedAt: updatedAt
                ),
            ]
        case Constants.priceChangeEventType:
            return (message.priceChanges ?? []).map { change in
                .bestPrices(
                    assetId: change.assetId,
                    bestBid: sidePrice(change.bestBid, emptySideMarker: Constants.emptyBidMarker),
                    bestAsk: sidePrice(change.bestAsk, emptySideMarker: Constants.emptyAskMarker),
                    updatedAt: updatedAt
                )
            }
        case Constants.lastTradeEventType:
            guard let assetId = message.assetId, let price = Decimal(stringValue: message.price) else {
                return []
            }

            return [.lastTrade(assetId: assetId, price: price, updatedAt: updatedAt)]
        default:
            return []
        }
    }

    func sidePrice(_ value: String?, emptySideMarker: Decimal) -> Decimal? {
        guard let price = Decimal(stringValue: value), price != emptySideMarker else {
            return nil
        }

        return price
    }

    func date(fromMilliseconds milliseconds: String?) -> Date? {
        guard let milliseconds, let value = TimeInterval(milliseconds) else {
            return nil
        }

        return Date(timeIntervalSince1970: value / 1000)
    }
}

// MARK: - Constants

private enum Constants {
    static let ping = "PING"
    static let pong = "PONG"
    static let pingInterval: Duration = .seconds(10)
    static let bookEventType = "book"
    static let priceChangeEventType = "price_change"
    static let lastTradeEventType = "last_trade_price"
    static let emptyAskMarker: Decimal = 1
    static let emptyBidMarker: Decimal = 0
}
