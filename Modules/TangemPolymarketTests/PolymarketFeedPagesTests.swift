//
//  PolymarketFeedPagesTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("PolymarketFeedPages")
struct PolymarketFeedPagesTests {
    // MARK: - Appending

    @Test("A page keeps the cursor it was asked for, which is what a refresh of it asks again")
    func pageKeepsItsCursor() {
        var feed = PolymarketFeedPages()

        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)
        feed.append(events: [Self.event("b")], requestCursor: "cursor-1", at: Self.start)

        #expect(feed.pages.map(\.requestCursor) == [nil, "cursor-1"])
    }

    @Test("An event the feed already holds stays on the page it first arrived on")
    func duplicatesStayOnTheirFirstPage() {
        var feed = PolymarketFeedPages()

        feed.append(events: [Self.event("a"), Self.event("b")], requestCursor: nil, at: Self.start)
        let fresh = feed.append(events: [Self.event("b"), Self.event("c")], requestCursor: "cursor-1", at: Self.start)

        #expect(fresh.map(\.id) == ["c"])
        #expect(feed.pages.first?.events.map(\.id) == ["a", "b"])
        #expect(feed.pages.last?.events.map(\.id) == ["c"])
        #expect(feed.events.map(\.id) == ["a", "b", "c"])
    }

    @Test("A page that adds nothing is not kept: it has nothing to refresh")
    func emptyPageIsNotKept() {
        var feed = PolymarketFeedPages()

        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)
        feed.append(events: [Self.event("a")], requestCursor: "cursor-1", at: Self.start)

        #expect(feed.pages.count == 1)
    }

    // MARK: - Merging

    @Test("A refresh replaces what the page holds and never what it holds it in")
    func mergeKeepsOrderAndMembership() throws {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a"), Self.event("b")], requestCursor: nil, at: Self.start)

        let pageID = try #require(feed.pages.first?.id)

        let merged = feed.merge(
            [Self.event("b", title: "fresh b"), Self.event("z"), Self.event("a", title: "fresh a")],
            into: pageID,
            at: Self.start
        )

        #expect(merged == 2)
        #expect(feed.events.map(\.id) == ["a", "b"])
        #expect(feed.events.map(\.title) == ["fresh a", "fresh b"])
    }

    @Test("An event the answer no longer carries is left as it was rather than dropped")
    func mergeKeepsWhatTheAnswerOmits() throws {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a", title: "old a"), Self.event("b")], requestCursor: nil, at: Self.start)

        let pageID = try #require(feed.pages.first?.id)
        feed.merge([Self.event("b", title: "fresh b")], into: pageID, at: Self.start)

        #expect(feed.events.map(\.title) == ["old a", "fresh b"])
    }

    @Test("A page that is gone cannot be merged into")
    func mergeIntoMissingPageIsRefused() {
        var feed = PolymarketFeedPages()

        #expect(feed.merge([Self.event("a")], into: 0, at: Self.start) == 0)
    }

    @Test("An answer that carries nothing the page holds leaves the page as stale as it was")
    func mergeThatReplacesNothingDoesNotRefreshThePage() throws {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)

        let pageID = try #require(feed.pages.first?.id)

        #expect(feed.merge([Self.event("z")], into: pageID, at: Self.start.addingTimeInterval(30)) == 0)

        let stale = feed.stalePageIDs(
            showing: ["a"],
            now: Self.start.addingTimeInterval(55),
            staleAfter: 20,
            minimumInterval: 20
        )

        #expect(stale == [pageID])
    }

    // MARK: - Staleness

    @Test("Only the pages the user is looking at are considered")
    func onlyVisiblePagesAreConsidered() throws {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)
        feed.append(events: [Self.event("b")], requestCursor: "cursor-1", at: Self.start)

        let secondPageID = try #require(feed.pages.last?.id)

        let stale = feed.stalePageIDs(
            showing: ["b"],
            now: Self.start.addingTimeInterval(60),
            staleAfter: 20,
            minimumInterval: 20
        )

        #expect(stale == [secondPageID])
    }

    @Test("A page answered inside the window is left alone")
    func freshPageIsLeftAlone() {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)

        let stale = feed.stalePageIDs(
            showing: ["a"],
            now: Self.start.addingTimeInterval(19),
            staleAfter: 20,
            minimumInterval: 20
        )

        #expect(stale.isEmpty)
    }

    @Test("A page that just failed is not asked again before the interval is out")
    func failedPageIsNotHammered() throws {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)

        let pageID = try #require(feed.pages.first?.id)
        feed.markAttempt(pageID: pageID, at: Self.start.addingTimeInterval(30))

        let tooSoon = feed.stalePageIDs(
            showing: ["a"],
            now: Self.start.addingTimeInterval(40),
            staleAfter: 20,
            minimumInterval: 20
        )

        let due = feed.stalePageIDs(
            showing: ["a"],
            now: Self.start.addingTimeInterval(50),
            staleAfter: 20,
            minimumInterval: 20
        )

        #expect(tooSoon.isEmpty)
        #expect(due == [pageID])
    }

    @Test("A successful refresh restarts the staleness window, a bare attempt does not")
    func onlyAnAnswerRestartsTheWindow() throws {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)

        let pageID = try #require(feed.pages.first?.id)
        feed.merge([Self.event("a")], into: pageID, at: Self.start.addingTimeInterval(30))

        let stale = feed.stalePageIDs(
            showing: ["a"],
            now: Self.start.addingTimeInterval(45),
            staleAfter: 20,
            minimumInterval: 20
        )

        #expect(stale.isEmpty)
    }

    // MARK: - Failures

    @Test("Failures in a row add up on the page they happened to")
    func failuresAddUpPerPage() throws {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)
        feed.append(events: [Self.event("b")], requestCursor: "cursor-1", at: Self.start)

        let firstPageID = try #require(feed.pages.first?.id)
        let lastPageID = try #require(feed.pages.last?.id)

        feed.markFailure(pageID: firstPageID)
        let failures = feed.markFailure(pageID: firstPageID)

        #expect(failures == 2)
        #expect(feed.page(id: lastPageID)?.failureCount == 0)
    }

    @Test("An answer in between starts the count over, even one that changes nothing")
    func answerResetsFailures() throws {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)

        let pageID = try #require(feed.pages.first?.id)

        feed.markFailure(pageID: pageID)
        feed.markFailure(pageID: pageID)
        feed.merge([Self.event("z")], into: pageID, at: Self.start.addingTimeInterval(20))
        let failures = feed.markFailure(pageID: pageID)

        #expect(failures == 1)
    }

    @Test("A page that is gone has no failures to count")
    func gonePageCountsNothing() {
        var feed = PolymarketFeedPages()

        #expect(feed.markFailure(pageID: 0) == 0)
    }

    @Test("Nothing on screen means nothing to refresh")
    func nothingVisibleRefreshesNothing() {
        var feed = PolymarketFeedPages()
        feed.append(events: [Self.event("a")], requestCursor: nil, at: Self.start)

        #expect(feed.pageIDs(showing: []).isEmpty)
    }
}

// MARK: - Fixtures

private extension PolymarketFeedPagesTests {
    static let start = Date(timeIntervalSince1970: 1_787_300_000)

    static func event(_ id: String, title: String = "Event") -> PolymarketEvent {
        PolymarketEvent(
            id: id,
            slug: id,
            title: title,
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isLive: false,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: 1,
            isNegRisk: false,
            displayMode: .plainMarkets,
            markets: []
        )
    }
}
