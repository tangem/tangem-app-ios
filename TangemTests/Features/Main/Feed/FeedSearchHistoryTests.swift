// Copyright © 2026 Tangem AG. All rights reserved.

import Combine
import Foundation
import Testing
@testable import Tangem

@Suite("Feed recent search limits")
@MainActor
struct FeedSearchHistoryTests {
    @Test("Queries retain three entries, move a repeated query first, and ignore blank input")
    func queryCapacity() {
        let provider = CommonFeedSearchHistoryProvider(storage: Storage(history: .empty))
        var history = FeedSearchHistory.empty
        let subscription = provider.historyPublisher.sink { history = $0 }
        defer { subscription.cancel() }

        for index in 1 ... 7 {
            provider.save(query: "query \(index)")
        }
        #expect(history.queries.map(\.value) == ["query 7", "query 6", "query 5"])
        provider.save(query: "  query 6  ")
        provider.save(query: " \n ")
        #expect(history.queries.map(\.value) == ["query 6", "query 7", "query 5"])
        provider.remove(FeedRecentQuery(value: "query 7"))
        #expect(history.queries.map(\.value) == ["query 6", "query 5"])
        provider.clear()
        #expect(history.queries.isEmpty)
    }

    @Test("Older stored history is bounded immediately after loading")
    func loadingOldHistory() {
        let stored = StoredFeedSearchHistory(queries: (1 ... 10).map { "query \($0)" })
        let provider = CommonFeedSearchHistoryProvider(storage: Storage(history: stored))
        var history = FeedSearchHistory.empty
        let subscription = provider.historyPublisher.sink { history = $0 }
        defer { subscription.cancel() }

        #expect(history.queries.map(\.value) == (1 ... 3).map { "query \($0)" })
    }

    @Test("Legacy token history is ignored without losing recent queries")
    func decodeLegacyHistory() throws {
        let data = Data(#"{"queries":["bitcoin","ethereum"],"tokens":[{"id":"bitcoin"}]}"#.utf8)
        let history = try JSONDecoder().decode(StoredFeedSearchHistory.self, from: data)
        #expect(history.queries == ["bitcoin", "ethereum"])

        let encoded = try JSONEncoder().encode(history)
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(object["tokens"] == nil)
    }

    private struct Storage: FeedSearchHistoryStorage {
        let history: StoredFeedSearchHistory

        func load() -> StoredFeedSearchHistory? { history }
        func save(_ history: StoredFeedSearchHistory) {}
    }
}
