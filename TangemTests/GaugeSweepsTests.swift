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
    private let capDeg: CGFloat = 12
    /// Derived from the production constant so the tests track it instead of hardcoding the angle.
    private var floorDeg: CGFloat { GaugeSweeps.Constants.minVisualSweepFraction * 360 }

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
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.8, 0.15, 0.05])
        #expect(abs(actual[2] - floorDeg) < tolerance)
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
        // Proportion between the two large slices is preserved (288 / 54).
        #expect(abs(actual[0] / actual[1] - 288 / 54) < tolerance)
    }

    @Test
    func zeroWeightSlicesAmongRealOnesStayZero() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.9, 0, 0.08, 0.02])
        #expect(actual[1] == 0)
        #expect(abs(actual[3] - floorDeg) < tolerance)
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
    }

    @Test
    func singleTinySegmentGrowsIntoTrackUpToFloor() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.02])
        #expect(abs(actual[0] - floorDeg) < tolerance)
    }

    @Test
    func filledSumBelowCircleAndFloorsFitPreservesFilledSum() {
        let weights: [CGFloat] = [0.4, 0.07, 0.03]
        let filledSum = (0.4 + 0.07 + 0.03) * 360
        let actual = GaugeSweeps.visualSweepAngles(weights: weights)
        #expect(abs(actual[2] - floorDeg) < tolerance)
        #expect(abs(actual.reduce(0, +) - filledSum) < tolerance)
    }

    @Test
    func moreSegmentsThanTheFloorAllowsFallsBackToEqualSplit() {
        let actual = GaugeSweeps.visualSweepAngles(weights: Array(repeating: 0.04, count: 25))
        for value in actual {
            #expect(abs(value - 360 / 25) < tolerance)
        }
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
    }

    @Test
    func fullRingWithCapBumpsOnlyTheLastFlooredSlice() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.9, 0.05, 0.05], capDeg: capDeg)
        #expect(abs(actual[1] - floorDeg) < tolerance)
        #expect(actual[2] > actual[1])
        #expect(abs(actual.reduce(0, +) - 360) < tolerance)
    }

    @Test
    func gapWiderThanCapLeavesTheLastSliceUnbumped() {
        let actual = GaugeSweeps.visualSweepAngles(weights: [0.4, 0.05], capDeg: capDeg)
        #expect(abs(actual[1] - floorDeg) < tolerance)
    }
}
