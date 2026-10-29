//
//  PolymarketFeedLiveQuotesTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket
import TangemPolymarketUI

@MainActor
final class PolymarketFeedLiveQuotesTracker {
    let updates: AsyncStream<Update>

    private let reader: PolymarketLiveTopicsReader<String, PolymarketOutcomeQuote>
    private let updatesContinuation: AsyncStream<Update>.Continuation
    private let delayProvider: PollDelayProvider

    private var readerTask: Task<Void, Never>?
    private var pendingQuotes: [String: PolymarketOutcomeQuote] = [:]
    private var flushTask: Task<Void, Never>?

    var trackedAssetIds: Set<String> {
        reader.trackedTopics
    }

    init(
        quotes: @escaping @Sendable (Set<String>) async -> AsyncStream<PolymarketOutcomeQuote>,
        statusChanges: @escaping @Sendable () async -> AsyncStream<PolymarketWebSocketConnectionStatus>,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.delayProvider = delayProvider
        reader = PolymarketLiveTopicsReader(values: quotes, statusChanges: statusChanges)
        (updates, updatesContinuation) = AsyncStream.makeStream(of: Update.self)

        readerTask = Task { [weak self, readerUpdates = reader.updates] in
            for await update in readerUpdates {
                self?.handle(update)
            }
        }
    }

    convenience init(liveQuotes: PolymarketLiveQuotes) {
        self.init(
            quotes: { assetIds in await liveQuotes.quotes(for: assetIds) },
            statusChanges: { await liveQuotes.statusChanges() }
        )
    }

    deinit {
        readerTask?.cancel()
        flushTask?.cancel()
        updatesContinuation.finish()
    }

    func update(
        events: [PolymarketEvent],
        visibleEventIDs: Set<String>,
        isLive: (PolymarketEvent) -> Bool
    ) {
        reader.track(Set(eventsAround(visibleEventIDs, in: events).filter(isLive).flatMap(\.feedCardAssetIds)))
        pendingQuotes = pendingQuotes.filter { trackedAssetIds.contains($0.key) }
    }

    func pause() {
        reader.pause()
        dropPendingQuotes()
    }

    func resume() {
        reader.resume()
    }
}

// MARK: - Update

extension PolymarketFeedLiveQuotesTracker {
    enum Update: Sendable {
        case quotes(QuoteBatch)
        case connectionLost
    }

    struct QuoteBatch: Sendable {
        let quotesByAssetId: [String: PolymarketOutcomeQuote]
    }
}

// MARK: - Private

private extension PolymarketFeedLiveQuotesTracker {
    func eventsAround(_ visibleEventIDs: Set<String>, in events: [PolymarketEvent]) -> ArraySlice<PolymarketEvent> {
        guard let firstVisible = events.firstIndex(where: { visibleEventIDs.contains($0.id) }),
              let lastVisible = events.lastIndex(where: { visibleEventIDs.contains($0.id) }) else {
            return []
        }

        let lowerBound = max(events.startIndex, firstVisible - Constants.prefetchedNeighbours)
        let upperBound = min(events.index(before: events.endIndex), lastVisible + Constants.prefetchedNeighbours)

        return events[lowerBound ... upperBound]
    }

    func handle(_ update: PolymarketLiveTopicsReader<String, PolymarketOutcomeQuote>.Update) {
        switch update {
        case .value(let quote):
            enqueue(quote)
        case .connectionLost:
            dropPendingQuotes()
            updatesContinuation.yield(.connectionLost)
        case .reconnected:
            break
        }
    }

    func enqueue(_ quote: PolymarketOutcomeQuote) {
        guard trackedAssetIds.contains(quote.assetId) else {
            return
        }

        pendingQuotes[quote.assetId] = quote

        guard flushTask == nil else {
            return
        }

        flushTask = Task { [weak self, delayProvider] in
            do {
                try await delayProvider.wait(for: Constants.batchInterval)
            } catch {
                return
            }

            self?.flush()
        }
    }

    func flush() {
        flushTask = nil

        guard !pendingQuotes.isEmpty else {
            return
        }

        updatesContinuation.yield(.quotes(QuoteBatch(quotesByAssetId: pendingQuotes)))
        pendingQuotes = [:]
    }

    func dropPendingQuotes() {
        flushTask?.cancel()
        flushTask = nil
        pendingQuotes = [:]
    }
}

private extension PolymarketEvent {
    var feedCardAssetIds: [String] {
        PolymarketEventCard.Model.displayedMarkets(of: self)
            .flatMap(\.outcomes)
            .map(\.assetId)
            + (moneyline?.picks ?? []).map(\.outcome.assetId)
    }
}

// MARK: - Constants

private enum Constants {
    static let prefetchedNeighbours = 5
    static let batchInterval: TimeInterval = 0.3
}
