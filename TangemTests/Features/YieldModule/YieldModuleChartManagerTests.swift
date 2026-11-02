//
//  YieldModuleChartManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Yield module chart month ticks")
struct YieldModuleChartManagerTests {
    @Test("History shorter than a year is labelled with its own months at the bars where they begin")
    func shortHistoryUsesBucketMonths() throws {
        let ticks = try makeSUT().makeMonthTicks(bucketStarts: makeBucketStarts(from: "2026-09-01", count: 10, stepDays: 7))

        #expect(ticks == [0: "Sep", 5: "Oct", 9: "Nov"])
    }

    @Test("A partial first month too close to the next month start gives way to it")
    func partialFirstMonthIsDropped() throws {
        let ticks = try makeSUT().makeMonthTicks(bucketStarts: makeBucketStarts(from: "2026-09-29", count: 10, stepDays: 7))

        #expect(ticks == [1: "Oct", 5: "Nov", 9: "Dec"])
    }

    @Test("A full year is thinned to evenly spaced month starts, counted from the newest one")
    func fullYearIsThinnedToMonthStarts() throws {
        let ticks = try makeSUT().makeMonthTicks(bucketStarts: makeBucketStarts(from: "2025-11-14", count: 28, stepDays: 13))

        #expect(ticks == [4: "Jan", 11: "Apr", 18: "Jul", 25: "Oct"])
    }

    @Test("Fewer than two buckets produce no labels", arguments: [0, 1])
    func tooFewBucketsProduceNoTicks(count: Int) throws {
        let ticks = try makeSUT().makeMonthTicks(bucketStarts: makeBucketStarts(from: "2026-09-01", count: count, stepDays: 7))

        #expect(ticks.isEmpty)
    }
}

// MARK: - Helpers

private extension YieldModuleChartManagerTests {
    func makeSUT() -> CommonYieldModuleChartManager {
        CommonYieldModuleChartManager(locale: Locale(identifier: "en_US_POSIX"))
    }

    func makeBucketStarts(from start: String, count: Int, stepDays: Int) throws -> [Date] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let startDate = try #require(formatter.date(from: start))

        return (0 ..< count).map { startDate.addingTimeInterval(TimeInterval($0 * stepDays) * 86400) }
    }
}
