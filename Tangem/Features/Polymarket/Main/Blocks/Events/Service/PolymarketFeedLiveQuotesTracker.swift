//
//  PolymarketFeedLiveQuotesTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket
import TangemPolymarketUI

@MainActor
final class PolymarketFeedLiveQuotesTracker {
    let updates: AsyncStream<Update>

    private let quotes: @Sendable (Set<String>) async -> AsyncStream<PolymarketOutcomeQuote>
    private let updatesContinuation: AsyncStream<Update>.Continuation

    private(set) var trackedAssetIds: Set<String> = []
    private var quotesTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?
    private var pendingQuotes: [String: PolymarketOutcomeQuote] = [:]
    private var flushTask: Task<Void, Never>?
    private var isConnected = false
    private var isPaused = false

    init(
        quotes: @escaping @Sendable (Set<String>) async -> AsyncStream<PolymarketOutcomeQuote>,
        statusChanges: @escaping @Sendable () async -> AsyncStream<PolymarketWebSocketConnectionStatus>
    ) {
        self.quotes = quotes
        (updates, updatesContinuation) = AsyncStream.makeStream(of: Update.self)

        statusTask = Task { [weak self] in
            for await status in await statusChanges() {
                self?.connectionStatusChanged(status)
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
        quotesTask?.cancel()
        statusTask?.cancel()
        flushTask?.cancel()
        updatesContinuation.finish()
    }

    func update(events: [PolymarketEvent], visibleEventIDs: Set<String>) {
        guard !isPaused else {
            return
        }

        let assetIds = Set(
            eventsAround(visibleEventIDs, in: events)
                .filter(\.isLive)
                .flatMap(\.feedCardAssetIds)
        )

        guard assetIds != trackedAssetIds else {
            return
        }

        trackedAssetIds = assetIds
        pendingQuotes = pendingQuotes.filter { assetIds.contains($0.key) }
        startReadingQuotes(for: assetIds)
    }

    func pause() {
        isPaused = true
        trackedAssetIds = []
        flushTask?.cancel()
        flushTask = nil
        pendingQuotes = [:]
        startReadingQuotes(for: [])
    }

    func resume() {
        isPaused = false
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

    func startReadingQuotes(for assetIds: Set<String>) {
        let previousTask = quotesTask

        guard !assetIds.isEmpty else {
            previousTask?.cancel()
            quotesTask = nil
            return
        }

        quotesTask = Task { [weak self, quotes] in
            let stream = await quotes(assetIds)
            previousTask?.cancel()

            for await quote in stream {
                guard !Task.isCancelled else {
                    return
                }

                self?.enqueue(quote)
            }
        }
    }

    func enqueue(_ quote: PolymarketOutcomeQuote) {
        pendingQuotes[quote.assetId] = quote

        guard flushTask == nil else {
            return
        }

        flushTask = Task { [weak self] in
            do {
                try await Task.sleep(for: Constants.batchInterval)
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

    func connectionStatusChanged(_ status: PolymarketWebSocketConnectionStatus) {
        guard status != .connected else {
            isConnected = true
            return
        }

        guard isConnected else {
            return
        }

        isConnected = false
        flushTask?.cancel()
        flushTask = nil
        pendingQuotes = [:]

        quotesTask?.cancel()
        quotesTask = nil

        if status != .stopped {
            startReadingQuotes(for: trackedAssetIds)
        }

        updatesContinuation.yield(.connectionLost)
    }
}

private extension PolymarketEvent {
    var feedCardAssetIds: [String] {
        PolymarketEventCard.Model.displayedMarkets(of: self)
            .flatMap(\.outcomes)
            .map(\.assetId)
    }
}

// MARK: - Constants

private enum Constants {
    static let prefetchedNeighbours = 5
    static let batchInterval: Duration = .milliseconds(300)
}
