//
//  CompositeNotificationBadgeCounterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
@testable import Tangem

@Suite("Composite notification badge counter")
struct CompositeNotificationBadgeCounterTests {
    @Test("No counters make a zero")
    func noCountersMakeZero() {
        let published = record(CompositeNotificationBadgeCounter(counters: [])) {}

        #expect(published == [0])
    }

    @Test("A counter that hasn't given its count yet counts as zero instead of holding the sum back")
    func silentCounterCountsAsZero() {
        let first = NotificationBadgeCounterStub()
        let second = NotificationBadgeCounterStub()

        let published = record(CompositeNotificationBadgeCounter(counters: [first, second])) {
            first.send(1)
        }

        #expect(published == [0, 1])
    }

    @Test("The sum follows the latest count of every counter")
    func sumFollowsLatestCounts() {
        let first = NotificationBadgeCounterStub()
        let second = NotificationBadgeCounterStub()

        let published = record(CompositeNotificationBadgeCounter(counters: [first, second])) {
            first.send(1)
            second.send(2)
            first.send(4)
            second.send(0)
        }

        #expect(published == [0, 1, 3, 6, 4])
    }

    @Test("A change that leaves the sum as it is publishes nothing new")
    func unchangedSumIsNotRepublished() {
        let first = NotificationBadgeCounterStub()
        let second = NotificationBadgeCounterStub()

        let published = record(CompositeNotificationBadgeCounter(counters: [first, second])) {
            first.send(1)
            second.send(2)
            first.send(1)
        }

        #expect(published == [0, 1, 3])
    }
}

// MARK: - Helpers

private extension CompositeNotificationBadgeCounterTests {
    func record(_ counter: CompositeNotificationBadgeCounter, actions: () -> Void) -> [Int] {
        var published: [Int] = []
        let subscription = counter.notificationBadgeCountPublisher.sink { published.append($0) }

        actions()
        subscription.cancel()

        return published
    }
}

// MARK: - Stubs

private final class NotificationBadgeCounterStub: NotificationBadgeCounter {
    private let subject = PassthroughSubject<Int, Never>()

    var notificationBadgeCountPublisher: AnyPublisher<Int, Never> {
        subject.eraseToAnyPublisher()
    }

    func send(_ count: Int) {
        subject.send(count)
    }
}
