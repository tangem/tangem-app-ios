//
//  FeedDetentHeightsTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemUI
import Testing
@testable import Tangem

@Suite("FeedDetentHeights")
struct FeedDetentHeightsTests {
    @Test("Collapsed detent follows the search bar")
    func collapsedFollowsSearchBar() {
        let sut = FeedDetentHeights()
        var detents: [ShtorkaDetents] = []
        let cancellable = sut.detentsPublisher.sink { detents.append($0) }
        defer { cancellable.cancel() }

        sut.report(searchBar: 82)

        #expect(detents.last?.collapsed == .height(82))
    }

    @Test("Medium detent sums the measured blocks")
    func mediumSumsBlocks() {
        let sut = FeedDetentHeights()
        var detents: [ShtorkaDetents] = []
        let cancellable = sut.detentsPublisher.sink { detents.append($0) }
        defer { cancellable.cancel() }

        sut.report(searchBar: 70)
        sut.report(widgets: 180)
        sut.report(tabChips: 40)

        // 70 + 12 + 180 + (20 + 40) + 20
        #expect(detents.last?.medium == .height(342))
    }

    @Test("Chips spacing is dropped while the chips are not measured")
    func mediumWithoutChips() {
        let sut = FeedDetentHeights()
        var detents: [ShtorkaDetents] = []
        let cancellable = sut.detentsPublisher.sink { detents.append($0) }
        defer { cancellable.cancel() }

        sut.report(searchBar: 70)
        sut.report(widgets: 180)

        // 70 + 12 + 180 + 20
        #expect(detents.last?.medium == .height(282))
    }

    @Test("Bottom safe area is taken out of the medium detent")
    func mediumSubtractsSafeArea() {
        let sut = FeedDetentHeights()
        var detents: [ShtorkaDetents] = []
        let cancellable = sut.detentsPublisher.sink { detents.append($0) }
        defer { cancellable.cancel() }

        sut.report(searchBar: 70)
        sut.report(widgets: 180)
        sut.report(safeArea: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0))

        // 70 + 12 + 180 + 20 - 34
        #expect(detents.last?.medium == .height(248))
    }

    @Test("Repeated measurements are published once")
    func detentsPublishOnChange() {
        let sut = FeedDetentHeights()
        var count = 0
        let cancellable = sut.detentsPublisher.sink { _ in count += 1 }
        defer { cancellable.cancel() }

        sut.report(searchBar: 82)
        sut.report(searchBar: 82)
        sut.report(widgets: 180)
        sut.report(widgets: 180)

        // The initial value, the search bar and the widgets.
        #expect(count == 3)
    }

    @Test("Drag frames never reach the detents")
    func dragFramesLeaveDetentsAlone() {
        let sut = FeedDetentHeights()
        sut.report(searchBar: 70)

        var count = 0
        let cancellable = sut.detentsPublisher.sink { _ in count += 1 }
        defer { cancellable.cancel() }

        sut.report(sheetHeight: 200)
        sut.report(sheetHeight: 400)
        sut.report(sheetHeight: 700)

        #expect(count == 1)
    }

    @Test("Progress runs from the collapsed height to the tallest sheet seen")
    func progressSpansTheTravel() {
        let sut = FeedDetentHeights()
        sut.report(searchBar: 100)

        var progress: [CGFloat] = []
        let cancellable = sut.expansionProgressPublisher.sink { progress.append($0) }
        defer { cancellable.cancel() }

        sut.report(sheetHeight: 700)
        #expect(progress.last == 1)

        sut.report(sheetHeight: 400)
        #expect(progress.last == 0.5)

        sut.report(sheetHeight: 100)
        #expect(progress.last == 0)
    }

    @Test("Progress stays within its bounds")
    func progressIsClamped() {
        let sut = FeedDetentHeights()
        sut.report(searchBar: 100)

        var progress: [CGFloat] = []
        let cancellable = sut.expansionProgressPublisher.sink { progress.append($0) }
        defer { cancellable.cancel() }

        sut.report(sheetHeight: 700)
        sut.report(sheetHeight: 40)

        #expect(progress.last == 0)
    }

    @Test("Repeated drag frames are published once")
    func progressPublishesOnChange() {
        let sut = FeedDetentHeights()
        sut.report(searchBar: 100)

        var count = 0
        let cancellable = sut.expansionProgressPublisher.sink { _ in count += 1 }
        defer { cancellable.cancel() }

        sut.report(sheetHeight: 700)
        sut.report(sheetHeight: 700)

        // The initial zero and the single change.
        #expect(count == 2)
    }
}
