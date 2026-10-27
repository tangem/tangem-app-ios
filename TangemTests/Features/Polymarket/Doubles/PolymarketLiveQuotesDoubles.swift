//
//  PolymarketLiveQuotesDoubles.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket
@testable import Tangem

final class PolymarketLiveQuotesSourceSpy: Sendable {
    let statuses = PolymarketLiveStreamSpy<PolymarketWebSocketConnectionStatus>()

    private let state = OSAllocatedUnfairLock(initialState: State())

    var streams: [PolymarketLiveStreamSpy<PolymarketOutcomeQuote>] {
        state.withLock { $0.streams.map(\.stream) }
    }

    var openStreamsAtRequest: [Int] {
        state.withLock { $0.streams.map(\.openStreamsAtRequest) }
    }

    @MainActor
    func makeTracker() -> PolymarketFeedLiveQuotesTracker {
        PolymarketFeedLiveQuotesTracker(
            quotes: { [self] assetIds in quotes(for: assetIds) },
            statusChanges: { [statuses] in statuses.makeStream() }
        )
    }

    private func quotes(for assetIds: Set<String>) -> AsyncStream<PolymarketOutcomeQuote> {
        let stream = PolymarketLiveStreamSpy<PolymarketOutcomeQuote>(assetIds: assetIds)

        state.withLock { state in
            let openStreams = state.streams.filter { !$0.stream.isCancelled }.count
            state.streams.append(Request(stream: stream, openStreamsAtRequest: openStreams))
        }

        return stream.makeStream()
    }

    private struct State {
        var streams: [Request] = []
    }

    private struct Request {
        let stream: PolymarketLiveStreamSpy<PolymarketOutcomeQuote>
        let openStreamsAtRequest: Int
    }
}

final class PolymarketLiveStreamSpy<Element: Sendable>: Sendable {
    let assetIds: Set<String>

    private let state = OSAllocatedUnfairLock(initialState: State())

    var pulls: Int {
        state.withLock { $0.pulls }
    }

    var isCancelled: Bool {
        state.withLock { $0.isCancelled }
    }

    init(assetIds: Set<String> = []) {
        self.assetIds = assetIds
    }

    func makeStream() -> AsyncStream<Element> {
        AsyncStream(unfolding: { [self] in await next() }, onCancel: { [self] in cancel() })
    }

    func push(_ element: Element) {
        let waiter = state.withLock { state -> CheckedContinuation<Element?, Never>? in
            guard let waiter = state.waiter else {
                state.pending.append(element)
                return nil
            }

            state.waiter = nil
            return waiter
        }

        waiter?.resume(returning: element)
    }

    private func next() async -> Element? {
        await withCheckedContinuation { continuation in
            let ready = state.withLock { state -> Element?? in
                state.pulls += 1

                guard !state.isCancelled else {
                    return .some(nil)
                }

                guard state.pending.isEmpty else {
                    return state.pending.removeFirst()
                }

                state.waiter = continuation
                return nil
            }

            if let ready {
                continuation.resume(returning: ready)
            }
        }
    }

    private func cancel() {
        let waiter = state.withLock { state in
            state.isCancelled = true
            defer { state.waiter = nil }
            return state.waiter
        }

        waiter?.resume(returning: nil)
    }

    private struct State {
        var pending: [Element] = []
        var waiter: CheckedContinuation<Element?, Never>?
        var pulls = 0
        var isCancelled = false
    }
}

enum PolymarketLiveQuotesFixtures {
    static func event(
        id: String,
        isLive: Bool = true,
        marketCount: Int = 1,
        groupItemTitle: String? = nil,
        probability: Decimal = Decimal(string: "0.42")!
    ) -> PolymarketEvent {
        let markets = (0 ..< marketCount).map { index in
            market(id: "\(id)-m\(index)", groupItemTitle: groupItemTitle, probability: probability)
        }

        return PolymarketEvent(
            id: id,
            slug: id,
            title: id,
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isLive: isLive,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: markets.count,
            isNegRisk: false,
            displayMode: .plainMarkets,
            markets: markets
        )
    }

    static func market(id: String, groupItemTitle: String? = nil, probability: Decimal = Decimal(string: "0.42")!) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: nil,
            title: id,
            groupItemTitle: groupItemTitle,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            isAcceptingOrders: true,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: 0,
            outcomes: [
                PolymarketOutcome(assetId: "\(id)-yes", title: "Yes", probability: probability),
                PolymarketOutcome(assetId: "\(id)-no", title: "No", probability: 1 - probability),
            ]
        )
    }

    static func assetIds(of event: PolymarketEvent, markets: Int = 1) -> Set<String> {
        Set(event.markets.prefix(markets).flatMap { $0.outcomes.map(\.assetId) })
    }

    static func quote(
        _ assetId: String,
        bid: String? = nil,
        ask: String? = nil,
        lastTrade: String? = nil
    ) -> PolymarketOutcomeQuote {
        PolymarketOutcomeQuote(
            assetId: assetId,
            bestBid: bid.flatMap { Decimal(string: $0) },
            bestAsk: ask.flatMap { Decimal(string: $0) },
            lastTradePrice: lastTrade.flatMap { Decimal(string: $0) },
            updatedAt: nil
        )
    }
}
