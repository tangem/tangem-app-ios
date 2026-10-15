//
//  PolymarketFeedPages.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketFeedPages {
    public private(set) var generation = UUID()

    private(set) var pages: [Page] = []

    public init() {}

    public var events: [PolymarketEvent] { pages.flatMap(\.events) }

    public var isEmpty: Bool { pages.isEmpty }

    public func page(id: Int) -> Page? {
        pages.first { $0.id == id }
    }

    public mutating func removeAll() {
        pages.removeAll()
        generation = UUID()
    }

    @discardableResult
    public mutating func append(
        events newEvents: [PolymarketEvent],
        requestCursor: String?,
        at date: Date
    ) -> [PolymarketEvent] {
        var known = Set(events.map(\.id))
        let fresh = newEvents.filter { known.insert($0.id).inserted }

        guard !fresh.isEmpty else { return [] }

        let id = (pages.map(\.id).max() ?? -1) + 1
        pages.append(Page(id: id, requestCursor: requestCursor, events: fresh, fetchedAt: date, lastAttemptAt: date, failureCount: 0))

        return fresh
    }

    public mutating func markAttempt(pageID: Int, at date: Date) {
        guard let index = pages.firstIndex(where: { $0.id == pageID }) else { return }

        pages[index].lastAttemptAt = date
    }

    @discardableResult
    public mutating func markFailure(pageID: Int) -> Int {
        guard let index = pages.firstIndex(where: { $0.id == pageID }) else { return 0 }

        pages[index].failureCount += 1

        return pages[index].failureCount
    }

    @discardableResult
    public mutating func merge(_ refreshed: [PolymarketEvent], into pageID: Int, at date: Date) -> Int {
        guard let index = pages.firstIndex(where: { $0.id == pageID }) else { return 0 }

        let byID = Dictionary(refreshed.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var replaced = 0

        pages[index].events = pages[index].events.map { event in
            guard let fresh = byID[event.id] else { return event }

            replaced += 1
            return fresh
        }

        pages[index].lastAttemptAt = date
        pages[index].failureCount = 0

        guard replaced > 0 else { return 0 }

        pages[index].fetchedAt = date

        return replaced
    }

    public func pageIDs(showing visibleEventIDs: Set<String>) -> [Int] {
        guard !visibleEventIDs.isEmpty else { return [] }

        return pages.filter { $0.events.contains { visibleEventIDs.contains($0.id) } }.map(\.id)
    }

    public func stalePageIDs(
        showing visibleEventIDs: Set<String>,
        now: Date,
        staleAfter: TimeInterval,
        minimumInterval: TimeInterval
    ) -> [Int] {
        pageIDs(showing: visibleEventIDs).filter { pageID in
            guard let page = page(id: pageID) else { return false }

            return now.timeIntervalSince(page.fetchedAt) >= staleAfter
                && now.timeIntervalSince(page.lastAttemptAt) >= minimumInterval
        }
    }
}

// MARK: - Page

public extension PolymarketFeedPages {
    struct Page {
        public let id: Int
        public let requestCursor: String?

        public internal(set) var events: [PolymarketEvent]

        public internal(set) var fetchedAt: Date
        public internal(set) var lastAttemptAt: Date
        public internal(set) var failureCount: Int
    }
}
