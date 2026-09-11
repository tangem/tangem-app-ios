//
//  GaugeSweepsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics
import Testing
@testable import Tangem

struct GaugeSweepsTests {
    private let tolerance: CGFloat = 0.01
    /// Derived from the production constant so the tests track it instead of hardcoding the angle.
    private var floorDeg: CGFloat { GaugeSweeps.Constants.minVisualSweepFraction * 360 }
    private var remainderFloorDeg: CGFloat { GaugeSweeps.Constants.minRemainderFraction * 360 }

    @Test
    func emptyWeightsReturnEmpty() {
        #expect(GaugeSweeps.visualSweepAngles(weights: []).isEmpty)
    }

    @Test
    func allZeroWeightsStayZeroAndPreserveSize() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0, 0, 0])
        #expect(actual == [0, 0, 0])
    }

    @Test
    func allSegmentsAboveFloorStayProportional() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.5, 0.3, 0.2])
        #expect(abs(actual[0] - 180) < tolerance)
        #expect(abs(actual[1] - 108) < tolerance)
        #expect(abs(actual[2] - 72) < tolerance)
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
    }

    @Test
    func segmentBelowFloorIsRaisedAndLargerOnesShrink() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.8, 0.195, 0.005])
        #expect(abs(actual[2] - floorDeg) < tolerance)
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
        // Proportion between the two large slices is preserved.
        #expect(abs(actual[0] / actual[1] - 0.8 / 0.195) < tolerance)
    }

    @Test
    func zeroWeightSlicesAmongRealOnesStayZero() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.9, 0, 0.095, 0.005])
        #expect(actual[1] == 0)
        #expect(abs(actual[3] - floorDeg) < tolerance)
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
    }

    @Test
    func singleTinySegmentGrowsIntoTrackUpToFloor() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.002])
        #expect(abs(actual[0] - floorDeg) < tolerance)
    }

    @Test
    func floorIsPinnedAtOnePercentOfTheCircle() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.001, 0.999])
        #expect(abs(actual[0] - 3.6) < tolerance)
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
    }

    @Test
    func filledSumBelowCircleAndFloorsFitPreservesFilledSum() {
        let weights: [CGFloat] = [0.4, 0.095, 0.005]
        let filledSum = (0.4 + 0.095 + 0.005) * 360
        let actual = GaugeSweeps.visualSweepAngles(weights: weights)
        #expect(abs(actual[2] - floorDeg) < tolerance)
        #expect(abs(actual.reduce(0, +) - filledSum) < tolerance)
    }

    @Test
    func moreSegmentsThanTheFloorAllowsFallsBackToEqualSplit() {
        let actual = GaugeSweeps.visualSweepAngles(weights: Array(repeating: 0.008, count: 125))
        for value in actual {
            #expect(abs(value - 360 / 125) < tolerance)
        }
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
    }

    @Test
    func aFullRingFloorsEveryTinySliceAlike() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.99, 0.005, 0.005])
        // The last slice is no longer widened: it laps over the first one instead of hiding under it.
        #expect(abs(actual[1] - floorDeg) < tolerance)
        #expect(abs(actual[2] - floorDeg) < tolerance)
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
    }

    @Test
    func nearlyFullWeightsStillLeaveTheRemainderVisible() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.5, 0.3, 0.1, 0.08])
        #expect(abs(actual.reduce(0, +) - (360 - remainderFloorDeg)) < tolerance)
        #expect(abs(actual[0] / actual[1] - 5 / 3) < tolerance)
    }

    @Test
    func remainderReserveStillHonoursTheSegmentFloors() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.95, 0.005, 0.005])
        #expect(abs(actual[1] - floorDeg) < tolerance)
        #expect(abs(actual[2] - floorDeg) < tolerance)
        #expect(abs(actual.reduce(0, +) - (360 - remainderFloorDeg)) < tolerance)
    }

    @Test
    func remainderWiderThanTheReserveIsLeftAsIs() {
        let weights: [CGFloat] = [0.5, 0.25, 0.05]
        let filledSum = (0.5 + 0.25 + 0.05) * 360
        let actual = GaugeSweeps.visualSweepAngles(weights: weights)
        #expect(abs(actual.reduce(0, +) - filledSum) < tolerance)
    }

    @Test
    func weightsSummingToOneWithinRoundingNoiseKeepFillingTheRing() {
        let third: CGFloat = 1.0 / 3
        let actual = GaugeSweeps.visualSweepAngles(weights: [third, third, third])
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
    }
}
