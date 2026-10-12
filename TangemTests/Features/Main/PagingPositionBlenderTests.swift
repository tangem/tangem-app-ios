//
//  PagingPositionBlenderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("PagingPositionBlender")
struct PagingPositionBlenderTests {
    @Test("Spans the two pages the swipe is between")
    func spansNeighbours() {
        let blender = PagingPositionBlender(position: 1.25, fallbackIndex: 0, pageCount: 3)

        #expect(blender.lowerIndex == 1)
        #expect(blender.upperIndex == 2)
        #expect(blender.upperWeight == 0.25)
    }

    @Test("Collapses onto a single page when the position is exactly on it")
    func collapsesOnWholePosition() {
        let blender = PagingPositionBlender(position: 2, fallbackIndex: 0, pageCount: 3)

        #expect(blender.lowerIndex == 2)
        #expect(blender.upperIndex == 2)
        #expect(blender.upperWeight == 0)
        #expect(blender { CGFloat($0) * 10 } == 20)
    }

    @Test("Falls back to the selected page while the position is unknown")
    func fallsBackWithoutPosition() {
        let blender = PagingPositionBlender(position: nil, fallbackIndex: 1, pageCount: 3)

        #expect(blender.lowerIndex == 1)
        #expect(blender.upperIndex == 1)
        #expect(blender.nearestIndex == 1)
    }

    @Test("Falls back to the selected page when there is nothing to blend between")
    func fallsBackForSinglePage() {
        let blender = PagingPositionBlender(position: 0.5, fallbackIndex: 0, pageCount: 1)

        #expect(blender.lowerIndex == 0)
        #expect(blender.upperIndex == 0)
        #expect(blender.upperWeight == 0)
    }

    @Test("Clamps a position that overscrolls past either end")
    func clampsOverscroll() {
        let underscrolled = PagingPositionBlender(position: -0.7, fallbackIndex: 1, pageCount: 3)
        #expect(underscrolled.lowerIndex == 0)
        #expect(underscrolled.upperIndex == 0)

        let overscrolled = PagingPositionBlender(position: 3.4, fallbackIndex: 1, pageCount: 3)
        #expect(overscrolled.lowerIndex == 2)
        #expect(overscrolled.upperIndex == 2)
    }

    @Test("Interpolates linearly between both reported values")
    func interpolatesBetweenReportedValues() {
        let blender = PagingPositionBlender(position: 0.25, fallbackIndex: 0, pageCount: 2)

        #expect(blender { index in index == 0 ? 100 : 200 } == 125)
    }

    @Test("Skips a page that has not reported instead of counting it as zero")
    func skipsUnreportedPage() {
        let blender = PagingPositionBlender(position: 0.5, fallbackIndex: 0, pageCount: 2)

        #expect(blender { index -> CGFloat? in index == 0 ? 80 : nil } == 80)
        #expect(blender { index -> CGFloat? in index == 1 ? 80 : nil } == 80)
    }

    @Test("Reports no value when neither page has reported")
    func returnsNilWhenNothingReported() {
        let blender = PagingPositionBlender(position: 0.5, fallbackIndex: 0, pageCount: 2)

        #expect(blender { _ -> CGFloat? in nil } == nil)
    }

    @Test("Highlights the page the swipe is closest to", arguments: [(position: CGFloat, nearestIndex: Int)]([
        (position: 1.0, nearestIndex: 1),
        (position: 1.49, nearestIndex: 1),
        (position: 1.5, nearestIndex: 2),
        (position: 1.9, nearestIndex: 2),
    ]))
    func highlightsNearestPage(position: CGFloat, nearestIndex: Int) {
        let blender = PagingPositionBlender(position: position, fallbackIndex: 0, pageCount: 3)

        #expect(blender.nearestIndex == nearestIndex)
    }
}
