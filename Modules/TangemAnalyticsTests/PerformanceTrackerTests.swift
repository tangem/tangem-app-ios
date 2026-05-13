//
//  PerformanceTrackerTests.swift
//  TangemAnalyticsTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemAnalytics

@Suite("PerformanceTracker — Firebase Performance trace lifecycle and idempotency")
struct PerformanceTrackerTests {
    @Test("startTracking returns nil in DEBUG builds (Firebase short-circuit)")
    func startTrackingReturnsNilInDebug() {
        let token = PerformanceTracker.startTracking(metric: .swapQuotesLoaded(providersCount: 3))
        #expect(token == nil)
    }

    @Test("endTracking with a nil token is a no-op for any result")
    func endTrackingWithNilTokenIsNoOp() {
        PerformanceTracker.endTracking(token: nil, with: .success)
        PerformanceTracker.endTracking(token: nil, with: .failure)
        PerformanceTracker.endTracking(token: nil, with: .unspecified)
    }

    @Test("PerformanceMetricToken.end runs the captured closure exactly once")
    func endRunsClosureOnce() {
        var calls: [PerformanceTracker.Result] = []
        let token = PerformanceMetricToken(traceName: "test_trace") { calls.append($0) }

        token.end(with: .success)

        #expect(calls == [.success])
    }

    @Test("PerformanceMetricToken.end is idempotent — subsequent calls do not re-invoke the closure")
    func endIsIdempotent() {
        var calls: [PerformanceTracker.Result] = []
        let token = PerformanceMetricToken(traceName: "test_trace") { calls.append($0) }

        token.end(with: .success)
        token.end(with: .failure)
        token.end(with: .unspecified)

        #expect(calls == [.success])
    }

    @Test("Concurrent end calls run the closure exactly once (lock-protected check-and-set)")
    func concurrentEndIsThreadSafe() {
        let lock = NSLock()
        var calls: [PerformanceTracker.Result] = []
        let token = PerformanceMetricToken(traceName: "test_trace") { result in
            lock.lock()
            defer { lock.unlock() }
            calls.append(result)
        }

        DispatchQueue.concurrentPerform(iterations: 1_000) { _ in
            token.end(with: .success)
        }

        #expect(calls == [.success])
    }
}
