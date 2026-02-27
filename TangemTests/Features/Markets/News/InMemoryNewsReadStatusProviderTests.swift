//
//  InMemoryNewsReadStatusProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Combine
import Testing
@testable import Tangem

@Suite(.tags(.news))
struct InMemoryNewsReadStatusProviderTests {
    @Test("Marks as read and publishes once per id")
    func marksAsReadAndPublishesOncePerId() {
        let provider = InMemoryNewsReadStatusProvider()
        var received: [NewsId] = []

        let cancellable = provider.readStatusChangedPublisher.sink { received.append($0) }

        provider.markAsRead(newsId: "1")
        provider.markAsRead(newsId: "1")
        provider.markAsRead(newsId: "2")

        #expect(provider.isRead(for: "1"))
        #expect(provider.isRead(for: "2"))
        #expect(received == ["1", "2"])

        _ = cancellable
    }

    @Test("isRead returns false for unknown ids")
    func isReadReturnsFalseForUnknownId() {
        let provider = InMemoryNewsReadStatusProvider()

        #expect(provider.isRead(for: "unknown") == false)
    }
}
