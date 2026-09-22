//
//  StoryHapticClusterizer.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The contract carries plain milliseconds, so how far apart the marks sit is all that tells a
/// series from single accents.
enum StoryHapticClusterizer {
    /// Measured between neighbours, so a chain of fast impulses stays one pattern however long.
    static let gapMs = 150

    static func clusters(from marks: [Int]) -> [HapticCluster] {
        let sanitized = Set(marks.filter { $0 >= 0 }).sorted()

        var series: [[Int]] = []
        for mark in sanitized {
            if let previous = series.last?.last, mark - previous < gapMs {
                series[series.count - 1].append(mark)
            } else {
                series.append([mark])
            }
        }

        return series.compactMap { marks in
            guard let start = marks.first else { return nil }
            return HapticCluster(startMs: start, offsets: marks.map { TimeInterval($0 - start) / 1000 })
        }
    }
}
