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
    @Test("Cold start does not place an unmeasured medium below collapsed")
    func coldStartUsesDefaultMedium() {
        let sut = FeedDetentHeights()
        sut.report(safeArea: EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0))
        sut.report(widgets: 0)
        sut.report(tabChips: 0)

        #expect(sut.detents.medium == ShtorkaDetents().medium)

        sut.report(widgets: 180)
        sut.report(tabChips: 36)

        #expect(sut.detents.medium == .height(290))
    }

    @Test("Transient zero measurements keep the last measured detents")
    func zeroMeasurementsPreserveDetents() {
        let sut = FeedDetentHeights()
        sut.report(safeArea: EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0))
        sut.report(searchBar: 76)
        sut.report(widgets: 180)
        sut.report(tabChips: 36)
        let measured = sut.detents

        sut.report(searchBar: 0)
        sut.report(widgets: 0)
        sut.report(tabChips: 0)

        #expect(sut.detents == measured)
    }

    @Test("Collapsed detent follows the search bar")
    func collapsedFollowsSearchBar() {
        let sut = FeedDetentHeights()
        var detents: [ShtorkaDetents] = []
        let cancellable = sut.detentsPublisher.sink { detents.append($0) }
        defer { cancellable.cancel() }

        sut.report(searchBar: 82)

        #expect(detents.last?.collapsed == .height(82 + FeedConstants.searchContentInset + FeedConstants.collapsedBottomInset))
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

        // Search block, widgets, tab spacing, tabs, and bottom inset.
        #expect(detents.last?.medium == .height(338))
    }

    @Test("Chips spacing is dropped while the chips are not measured")
    func mediumWithoutChips() {
        let sut = FeedDetentHeights()
        var detents: [ShtorkaDetents] = []
        let cancellable = sut.detentsPublisher.sink { detents.append($0) }
        defer { cancellable.cancel() }

        sut.report(searchBar: 70)
        sut.report(widgets: 180)

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
        sut.report(safeArea: EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0))

        var count = 0
        let cancellable = sut.detentsPublisher.sink { _ in count += 1 }
        defer { cancellable.cancel() }

        sut.report(sheetHeight: 200)
        sut.report(sheetHeight: 400)
        sut.report(sheetHeight: 700)
        sut.report(sheetHeight: 324)
        sut.report(sheetHeight: 76)

        #expect(count == 1)
    }

    @Test("Full to medium restores the material through intermediate heights")
    func fullToMediumRestoresMaterial() {
        let sut = makeMeasuredHeights()
        sut.report(sheetHeight: 1000)
        #expect(sut.expansionProgress == 1)
        sut.report(sheetHeight: 576)
        #expect(sut.expansionProgress == 0.5)
        sut.report(sheetHeight: 216)
        #expect(sut.expansionProgress == 0)
        sut.report(sheetHeight: 100)
        #expect(sut.expansionProgress == 0)
    }

    @Test("First expansion and reversing an unfinished drag use the same range")
    func firstExpansionDoesNotCalibrateItself() {
        let sut = makeMeasuredHeights()
        sut.report(sheetHeight: 396)
        #expect(sut.expansionProgress == 0.25)
        sut.report(sheetHeight: 576)
        #expect(sut.expansionProgress == 0.5)
        sut.report(sheetHeight: 396)
        #expect(sut.expansionProgress == 0.25)
    }

    @Test("Window resizing invalidates the full-height range immediately")
    func windowResizeRecalculatesProgress() {
        let sut = makeMeasuredHeights()
        sut.report(sheetHeight: 576)
        #expect(sut.expansionProgress == 0.5)
        sut.report(window: 616)
        #expect(sut.expansionProgress == 1)
        sut.report(window: 1016)
        #expect(sut.expansionProgress == 0.5)
    }

    @Test("Physical height does not add the bottom safe area twice")
    func physicalHeightCountsBottomInsetOnce() {
        let sut = makeMeasuredHeights()
        sut.report(safeArea: EdgeInsets(top: 60, leading: 0, bottom: 40, trailing: 0))
        sut.report(window: 1076)
        sut.report(sheetHeight: 216)
        #expect(sut.expansionProgress == 0)
        sut.report(sheetHeight: 576)
        #expect(sut.expansionProgress == 0.5)
    }

    @Test("A changed medium height updates the existing surface progress")
    func contentMeasurementUpdatesProgress() {
        let sut = makeMeasuredHeights()
        sut.report(sheetHeight: 576)
        #expect(sut.expansionProgress == 0.5)
        sut.report(widgets: 460)
        #expect(sut.expansionProgress == 0)
    }

    @Test("Missing window geometry and overscroll stay within bounds")
    func missingGeometryAndOverscroll() {
        let sut = FeedDetentHeights()
        sut.report(sheetHeight: 600)
        #expect(sut.expansionProgress == 0)
        sut.report(window: 800)
        sut.report(sheetHeight: 900)
        #expect(sut.expansionProgress == 1)
        sut.report(sheetHeight: 0)
        #expect(sut.expansionProgress == 0)
    }

    @Test("Cold start and transient empty measurements preserve usable detents")
    func startupDetentsStayOrdered() {
        let sut = FeedDetentHeights()
        sut.report(safeArea: EdgeInsets(top: 60, leading: 0, bottom: 40, trailing: 0))
        #expect(sut.detents.medium == ShtorkaDetents().medium)
        sut.report(widgets: 180)
        let measured = sut.detents
        sut.report(widgets: 0)
        sut.report(searchBar: 0)
        #expect(sut.detents == measured)
    }

    @Test("Repeated drag frames are published once")
    func progressPublishesOnChange() {
        let sut = makeMeasuredHeights()
        var count = 0
        let cancellable = sut.expansionProgressPublisher.sink { _ in count += 1 }
        defer { cancellable.cancel() }
        sut.report(sheetHeight: 1000)
        sut.report(sheetHeight: 1000)
        #expect(count == 2)
    }

    private func makeMeasuredHeights() -> FeedDetentHeights {
        let sut = FeedDetentHeights()
        sut.report(searchBar: 84)
        sut.report(widgets: 100)
        sut.report(window: 1016)
        return sut
    }
}
