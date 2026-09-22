//
//  StoryHapticClusterizerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemStories

@Suite("Stories V2 haptic clusterizer")
struct StoryHapticClusterizerTests {
    @Test
    func noMarksProduceNoClusters() {
        #expect(StoryHapticClusterizer.clusters(from: []).isEmpty)
    }

    @Test
    func aSingleMarkBecomesOneImpulse() {
        let clusters = StoryHapticClusterizer.clusters(from: [4700])

        #expect(clusters == [HapticCluster(startMs: 4700, offsets: [0])])
        #expect(clusters[0].isBurst == false)
    }

    @Test
    func neighbouringMarksShareAPattern() {
        let clusters = StoryHapticClusterizer.clusters(from: [1450, 1560])

        #expect(clusters.count == 1)
        #expect(clusters[0].startMs == 1450)
        #expect(clusters[0].offsets == [0, 0.11])
    }

    @Test
    func distantMarksBecomeSeparatePatterns() {
        let clusters = StoryHapticClusterizer.clusters(from: [600, 1050])

        #expect(clusters.map(\.startMs) == [600, 1050])
        #expect(clusters.allSatisfy { $0.offsets == [0] })
    }

    @Test
    func marksExactlyTheGapApartDoNotShareAPattern() {
        let clusters = StoryHapticClusterizer.clusters(from: [0, StoryHapticClusterizer.gapMs])

        #expect(clusters.count == 2)
    }

    @Test
    func aFastSeriesStaysOnePatternHoweverLongItRuns() {
        // 330 ms end to end, well past the grouping gap, but every neighbouring pair is inside it.
        let marks = (0 ..< 12).map { 350 + $0 * 30 }

        let clusters = StoryHapticClusterizer.clusters(from: marks)

        #expect(clusters.count == 1)
        #expect(clusters[0].startMs == 350)
        #expect(clusters[0].offsets.count == 12)
        #expect(clusters[0].isBurst)
        #expect(abs(clusters[0].offsets.last! - 0.33) < 0.0001)
    }

    @Test
    func marksAreSortedAndDeduplicated() {
        let clusters = StoryHapticClusterizer.clusters(from: [1050, 600, 1050, -20])

        #expect(clusters.map(\.startMs) == [600, 1050])
    }

    @Test
    func aSlideMixesSingleTapsSeriesAndConfirmations() {
        let clusters = StoryHapticClusterizer.clusters(from: [250, 280, 310, 340, 1500, 1610])

        #expect(clusters.map(\.startMs) == [250, 1500])
        #expect(clusters[0].isBurst)
        #expect(clusters[1].offsets == [0, 0.11])
    }
}
