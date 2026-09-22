//
//  GeoDefinerTestSupport.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

/// Use this tag for all geo suites: @Suite(.tags(.geoDefiner))
extension Tag {
    @Tag static var geoDefiner: Self
}

final class InMemoryGeoIpRegionCodeStorage: GeoIpRegionCodeStoring {
    private struct State {
        var regionCode: String?
        var updateDate: Date?
    }

    private let state: OSAllocatedUnfairLock<State>

    init(regionCode: String? = nil, updateDate: Date? = nil) {
        state = OSAllocatedUnfairLock(initialState: State(regionCode: regionCode, updateDate: updateDate))
    }

    var geoIpRegionCode: String? {
        get { state.withLock { $0.regionCode } }
        set { state.withLock { $0.regionCode = newValue } }
    }

    var geoIpRegionCodeUpdateDate: Date? {
        get { state.withLock { $0.updateDate } }
        set { state.withLock { $0.updateDate = newValue } }
    }
}

/// Wall and monotonic clocks that move only when a test moves them, so TTL and throttle windows are deterministic.
final class GeoTestClock {
    private struct State {
        var wall: Date
        var monotonic: ContinuousClock.Instant
    }

    private let state: OSAllocatedUnfairLock<State>

    init(wall: Date = Date(timeIntervalSince1970: 1_800_000_000)) {
        state = OSAllocatedUnfairLock(initialState: State(wall: wall, monotonic: .now))
    }

    var wall: Date {
        get { state.withLock { $0.wall } }
        set { state.withLock { $0.wall = newValue } }
    }

    func advanceMonotonic(by duration: Duration) {
        state.withLock { $0.monotonic = $0.monotonic.advanced(by: duration) }
    }

    func now() -> Date {
        wall
    }

    func monotonicNow() -> ContinuousClock.Instant {
        state.withLock { $0.monotonic }
    }
}

/// Records geo requests reaching the API and answers with a canned code, an error, or holds the request
/// until the test releases it.
final class GeoApiSpy {
    enum Reply {
        case regionCode(String)
        case failure
        case suspended
    }

    private struct State {
        var reply: Reply
        var callCount = 0
        var pending: [CheckedContinuation<String, Error>] = []
    }

    let fake = FakeTangemApiService()

    private let state: OSAllocatedUnfairLock<State>

    init(reply: Reply) {
        let state = OSAllocatedUnfairLock(initialState: State(reply: reply))
        self.state = state

        fake.loadGeoHandler = {
            let reply = state.withLock { $0.reply }

            switch reply {
            case .regionCode(let regionCode):
                state.withLock { $0.callCount += 1 }
                return regionCode
            case .failure:
                state.withLock { $0.callCount += 1 }
                throw GeoApiSpyError.unavailable
            case .suspended:
                return try await withCheckedThrowingContinuation { continuation in
                    state.withLock { state in
                        state.pending.append(continuation)
                        state.callCount += 1
                    }
                }
            }
        }
    }

    var callCount: Int {
        state.withLock { $0.callCount }
    }

    var reply: Reply {
        get { state.withLock { $0.reply } }
        set { state.withLock { $0.reply = newValue } }
    }

    func resumeSuspendedRequests(with regionCode: String) {
        let pending = state.withLock { state in
            defer { state.pending.removeAll() }
            return state.pending
        }

        pending.forEach { $0.resume(returning: regionCode) }
    }
}

private enum GeoApiSpyError: Error {
    case unavailable
}
