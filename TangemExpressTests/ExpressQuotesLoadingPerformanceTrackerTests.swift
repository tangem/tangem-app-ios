//
//  ExpressQuotesLoadingPerformanceTrackerTests.swift
//  TangemExpressTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemAnalytics
@testable import TangemExpress

@Suite("Quote-loading performance tracker — fan-out aggregation across multiple providers")
struct ExpressQuotesLoadingPerformanceTrackerTests {
    // MARK: - Result aggregation

    @Test("Trace ends with `.success` when every provider fulfills without an error")
    func endsWithSuccessWhenAllProvidersFulfillWithoutError() {
        var recorded: [PerformanceTracker.Result] = []
        let tracker = ExpressQuotesLoadingPerformanceTracker(providersCount: 3) {
            recorded.append($0)
        }

        tracker.fulfill(hasError: false)
        tracker.fulfill(hasError: false)
        #expect(recorded.isEmpty, "Tracker must not end before the threshold is reached")

        tracker.fulfill(hasError: false)
        #expect(recorded == [.success])
    }

    @Test("Trace ends with `.failure` when at least one provider reports an error")
    func endsWithFailureWhenAnyProviderHasError() {
        var recorded: [PerformanceTracker.Result] = []
        let tracker = ExpressQuotesLoadingPerformanceTracker(providersCount: 3) {
            recorded.append($0)
        }

        tracker.fulfill(hasError: false)
        tracker.fulfill(hasError: true)
        tracker.fulfill(hasError: false)

        #expect(recorded == [.failure])
    }

    @Test("Trace ends with `.failure` when every provider reports an error")
    func endsWithFailureWhenAllProvidersHaveError() {
        var recorded: [PerformanceTracker.Result] = []
        let tracker = ExpressQuotesLoadingPerformanceTracker(providersCount: 2) {
            recorded.append($0)
        }

        tracker.fulfill(hasError: true)
        tracker.fulfill(hasError: true)

        #expect(recorded == [.failure])
    }

    @Test("Single-provider tracker ends as soon as that provider fulfills")
    func singleProviderFulfillsImmediately() {
        var recorded: [PerformanceTracker.Result] = []
        let tracker = ExpressQuotesLoadingPerformanceTracker(providersCount: 1) {
            recorded.append($0)
        }

        tracker.fulfill(hasError: false)

        #expect(recorded == [.success])
    }

    // MARK: - Deinit safety net

    @Test("Deinit ends the trace with `.unspecified` after only some providers fulfilled (e.g., cancellation)")
    func endsWithUnspecifiedOnDeinitWhenNotAllProvidersFulfilled() {
        var recorded: [PerformanceTracker.Result] = []
        do {
            let tracker = ExpressQuotesLoadingPerformanceTracker(providersCount: 3) {
                recorded.append($0)
            }
            tracker.fulfill(hasError: false)
        }

        #expect(recorded == [.unspecified])
    }

    @Test("Deinit ends the trace with `.unspecified` when no provider ever fulfilled")
    func endsWithUnspecifiedOnDeinitWhenNoProvidersFulfilled() {
        var recorded: [PerformanceTracker.Result] = []
        do {
            _ = ExpressQuotesLoadingPerformanceTracker(providersCount: 3) {
                recorded.append($0)
            }
        }

        #expect(recorded == [.unspecified])
    }

    // MARK: - Threshold semantics

    @Test("Fulfill calls beyond `providersCount` do not produce additional trace ends")
    func ignoresExtraFulfillsAfterThreshold() {
        var recorded: [PerformanceTracker.Result] = []
        let tracker = ExpressQuotesLoadingPerformanceTracker(providersCount: 2) {
            recorded.append($0)
        }

        tracker.fulfill(hasError: false)
        tracker.fulfill(hasError: false)
        tracker.fulfill(hasError: true)
        tracker.fulfill(hasError: false)

        #expect(recorded == [.success])
    }

    // MARK: - Concurrency

    @Test("100 concurrent clean fulfill calls aggregate to a single `.success` trace end")
    func handlesConcurrentFulfills() {
        let providersCount = 100
        var recorded: [PerformanceTracker.Result] = []
        let tracker = ExpressQuotesLoadingPerformanceTracker(providersCount: providersCount) {
            recorded.append($0)
        }

        DispatchQueue.concurrentPerform(iterations: providersCount) { _ in
            tracker.fulfill(hasError: false)
        }

        #expect(recorded == [.success])
    }

    @Test("100 concurrent fulfill calls with mixed errors aggregate to a single `.failure` trace end")
    func aggregatesErrorAcrossConcurrentFulfills() {
        let providersCount = 100
        var recorded: [PerformanceTracker.Result] = []
        let tracker = ExpressQuotesLoadingPerformanceTracker(providersCount: providersCount) {
            recorded.append($0)
        }

        DispatchQueue.concurrentPerform(iterations: providersCount) { iteration in
            tracker.fulfill(hasError: iteration % 2 == 1)
        }

        #expect(recorded == [.failure])
    }
}
