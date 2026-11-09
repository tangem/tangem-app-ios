//
//  PolymarketLiveTopicsReaderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket live topics reader", .timeLimit(.minutes(1)))
@MainActor
struct PolymarketLiveTopicsReaderTests {
    @Test("A real drop reports the loss and, once connected again, the reconnection")
    func dropThenReconnectIsReported() async throws {
        let env = try await makeSUT()

        env.statuses.push(.waitingToReconnect)
        env.statuses.push(.connecting)
        env.statuses.push(.connected)

        #expect(try await env.updates.next() == .connectionLost)
        #expect(try await env.updates.next() == .reconnected)
    }

    @Test("A socket closed on purpose and opened again is not a reconnection, so nothing is fetched again")
    func plannedCloseIsNotAReconnection() async throws {
        let env = try await makeSUT()

        env.statuses.push(.idle)
        env.statuses.push(.connecting)
        env.statuses.push(.connected)
        env.statuses.push(.waitingToReconnect)

        #expect(try await env.updates.next() == .connectionLost)
        #expect(try await env.updates.next() == .connectionLost)
    }

    @Test("A lost connection is reported once however many statuses it goes through")
    func lostConnectionIsReportedOnce() async throws {
        let env = try await makeSUT()

        env.statuses.push(.waitingToReconnect)
        env.statuses.push(.connecting)
        env.statuses.push(.waitingToReconnect)
        env.statuses.push(.connected)

        #expect(try await env.updates.next() == .connectionLost)
        #expect(try await env.updates.next() == .reconnected)
    }

    @Test("A stopped socket stops reading without opening a new stream")
    func stoppedSocketIsNotReadAgain() async throws {
        let env = try await makeSUT()
        env.sut.track(["a"])
        let stopped = try await env.values.requests.next()

        env.statuses.push(.stopped)
        #expect(try await env.updates.next() == .connectionLost)
        try await stopped.cancelled.next()

        env.statuses.push(.connected)
        #expect(try await env.updates.next() == .reconnected)
        env.sut.track(["b"])
        #expect(try await env.values.requests.next().assetIds == ["b"])
    }
}

// MARK: - Helpers

private extension PolymarketLiveTopicsReaderTests {
    func makeSUT() async throws -> Environment {
        let statuses = PolymarketLiveStreamSpy<PolymarketWebSocketConnectionStatus>()
        let values = ValuesSourceSpy()
        let sut = PolymarketLiveTopicsReader<String, Int>(
            values: { topics in values.makeStream(topics) },
            statusChanges: { statuses.makeStream() }
        )
        let updates = PolymarketTestSignal<RecordedReaderUpdate>()
        updates.record(sut.updates, transform: { RecordedReaderUpdate($0) })

        statuses.push(.connected)
        try await statuses.waitForPulls(2)

        return Environment(sut: sut, statuses: statuses, values: values, updates: updates)
    }

    struct Environment {
        let sut: PolymarketLiveTopicsReader<String, Int>
        let statuses: PolymarketLiveStreamSpy<PolymarketWebSocketConnectionStatus>
        let values: ValuesSourceSpy
        let updates: PolymarketTestSignal<RecordedReaderUpdate>
    }
}

// MARK: - Doubles

private final class ValuesSourceSpy: Sendable {
    let requests = PolymarketTestSignal<PolymarketLiveStreamSpy<Int>>()

    func makeStream(_ topics: Set<String>) -> AsyncStream<Int> {
        let stream = PolymarketLiveStreamSpy<Int>(assetIds: topics)
        requests.send(stream)
        return stream.makeStream()
    }
}

private enum RecordedReaderUpdate: Equatable {
    case value(Int)
    case connectionLost
    case reconnected

    init(_ update: PolymarketLiveTopicsReader<String, Int>.Update) {
        switch update {
        case .value(let value):
            self = .value(value)
        case .connectionLost:
            self = .connectionLost
        case .reconnected:
            self = .reconnected
        }
    }
}
