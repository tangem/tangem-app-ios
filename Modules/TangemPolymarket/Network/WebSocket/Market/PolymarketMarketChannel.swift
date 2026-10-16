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
        update.quote.assetId
    }

    func value(applying update: Update, to previous: PolymarketOutcomeQuote?) -> PolymarketOutcomeQuote {
        guard !update.isSnapshot else {
            return update.quote
        }

        return PolymarketOutcomeQuote(
            assetId: update.quote.assetId,
            bestBid: update.quote.bestBid ?? previous?.bestBid,
            bestAsk: update.quote.bestAsk ?? previous?.bestAsk,
            updatedAt: update.quote.updatedAt ?? previous?.updatedAt
        )
    }
}

// MARK: - Update

extension PolymarketMarketChannel {
    struct Update: Equatable, Sendable {
        let quote: PolymarketOutcomeQuote
        let isSnapshot: Bool
    }
}

// MARK: - Private

private extension PolymarketMarketChannel {
    func encode(_ value: some Encodable) throws -> WebSocketMessage {
        .text(String(decoding: try encoder.encode(value), as: UTF8.self))
    }

    func updates(fromDTO message: PolymarketDTO.MarketChannelMessage) -> [Update] {
        let updatedAt = date(fromMilliseconds: message.timestamp)

        if let priceChanges = message.priceChanges {
            return priceChanges.map { change in
                Update(
                    quote: PolymarketOutcomeQuote(
                        assetId: change.assetId,
                        bestBid: Decimal(stringValue: change.bestBid),
                        bestAsk: Decimal(stringValue: change.bestAsk),
                        updatedAt: updatedAt
                    ),
                    isSnapshot: false
                )
            }
        }

        if let assetId = message.assetId, let bids = message.bids, let asks = message.asks {
            return [
                Update(
                    quote: PolymarketOutcomeQuote(
                        assetId: assetId,
                        bestBid: bids.compactMap { Decimal(stringValue: $0.price) }.max(),
                        bestAsk: asks.compactMap { Decimal(stringValue: $0.price) }.min(),
                        updatedAt: updatedAt
                    ),
                    isSnapshot: true
                ),
            ]
        }

        return []
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
}
