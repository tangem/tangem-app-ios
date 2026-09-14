// Copyright © 2026 Tangem AG. All rights reserved.

import Combine
import Testing
@testable import Tangem

@Suite("Feed recent search limits")
@MainActor
struct FeedSearchHistoryTests {
    @Test("Queries retain five entries, move a repeated query first, and ignore blank input")
    func queryCapacity() {
        let provider = CommonFeedSearchHistoryProvider(storage: Storage(history: .empty))
        var history = FeedSearchHistory.empty
        let subscription = provider.historyPublisher.sink { history = $0 }
        defer { subscription.cancel() }

        for index in 1 ... 7 {
            provider.save(query: "query \(index)")
        }
        #expect(history.queries.map(\.value) == ["query 7", "query 6", "query 5", "query 4", "query 3"])
        provider.save(query: "  query 4  ")
        provider.save(query: " \n ")
        #expect(history.queries.map(\.value) == ["query 4", "query 7", "query 6", "query 5", "query 3"])
        provider.remove(FeedRecentQuery(value: "query 7"))
        #expect(history.queries.count == 4)
        provider.clear()
        #expect(history.queries.isEmpty)
    }

    @Test("Tokens retain ten unique entries independently of queries")
    func tokenCapacity() {
        let provider = CommonFeedSearchHistoryProvider(storage: Storage(history: .empty))
        var history = FeedSearchHistory.empty
        let subscription = provider.historyPublisher.sink { history = $0 }
        defer { subscription.cancel() }

        for index in 1 ... 12 {
            provider.save(token: token(index))
        }
        provider.save(token: token(5))
        #expect(history.tokens.map(\.id) == ["5", "12", "11", "10", "9", "8", "7", "6", "4", "3"])
        #expect(history.queries.isEmpty)
    }

    @Test("Older stored history is bounded immediately after loading")
    func loadingOldHistory() {
        let stored = StoredFeedSearchHistory(queries: (1 ... 10).map { "query \($0)" }, tokens: (1 ... 12).map(token))
        let provider = CommonFeedSearchHistoryProvider(storage: Storage(history: stored))
        var history = FeedSearchHistory.empty
        let subscription = provider.historyPublisher.sink { history = $0 }
        defer { subscription.cancel() }

        #expect(history.queries.map(\.value) == (1 ... 5).map { "query \($0)" })
        #expect(history.tokens.map(\.id) == (1 ... 10).map { String($0) })
    }

    private func token(_ index: Int) -> MarketsTokenModel {
        MarketsTokenModel(
            id: String(index), name: "Token \(index)", symbol: "T\(index)", currentPrice: nil,
            priceChangePercentage: [:], marketRating: nil, maxYieldApy: nil, marketCap: nil,
            isUnderMarketCapLimit: nil, stakingOpportunities: nil, networks: nil, restrictedForCountry: nil
        )
    }

    private struct Storage: FeedSearchHistoryStorage {
        let history: StoredFeedSearchHistory

        func load() -> StoredFeedSearchHistory? { history }
        func save(_ history: StoredFeedSearchHistory) {}
    }
}
