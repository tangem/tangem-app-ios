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

@Suite("Polymarket live topics reader")
@MainActor
struct PolymarketLiveTopicsReaderTests {
    @Test("A real drop reports the loss and, once connected again, the reconnection")
    func dropThenReconnectIsReported() async throws {
        let env = try await makeSUT()

        env.statuses.push(.waitingToReconnect)
        env.statuses.push(.connecting)
        env.statuses.push(.connected)

        try await settle { env.recorder.updates == [.connectionLost, .reconnected] }
    }

    @Test("A socket closed on purpose and opened again is not a reconnection, so nothing is fetched again")
    func plannedCloseIsNotAReconnection() async throws {
        let env = try await makeSUT()

        env.statuses.push(.idle)
        env.statuses.push(.connecting)
        env.statuses.push(.connected)
        try await settle { env.statuses.pulls >= 5 }
        try await drain()

        #expect(env.recorder.updates == [.connectionLost])
    }

    @Test("A stopped socket stops reading without opening a new stream")
    func stoppedSocketIsNotReadAgain() async throws {
        let env = try await makeSUT()
        env.sut.track(["a"])
        try await settle { env.values.streams.count == 1 }

        env.statuses.push(.stopped)
        try await settle { env.recorder.updates == [.connectionLost] }
        try await drain()

        #expect(env.values.streams.count == 1)
        #expect(env.values.streams[0].isCancelled)
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
        let recorder = ReaderUpdatesRecorder(updates: sut.updates)

        statuses.push(.connected)
        try await settle { statuses.pulls >= 2 }

        return Environment(sut: sut, statuses: statuses, values: values, recorder: recorder)
    }

    struct Environment {
        let sut: PolymarketLiveTopicsReader<String, Int>
        let statuses: PolymarketLiveStreamSpy<PolymarketWebSocketConnectionStatus>
        let values: ValuesSourceSpy
        let recorder: ReaderUpdatesRecorder
    }
}

// MARK: - Doubles

private final class ValuesSourceSpy: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: [PolymarketLiveStreamSpy<Int>]())

    var streams: [PolymarketLiveStreamSpy<Int>] {
        state.withLock { $0 }
    }

    func makeStream(_ topics: Set<String>) -> AsyncStream<Int> {
        let stream = PolymarketLiveStreamSpy<Int>(assetIds: topics)
        state.withLock { $0.append(stream) }
        return stream.makeStream()
    }
}

@MainActor
private final class ReaderUpdatesRecorder {
    private(set) var updates: [RecordedReaderUpdate] = []

    init(updates: AsyncStream<PolymarketLiveTopicsReader<String, Int>.Update>) {
        Task { [weak self] in
            for await update in updates {
                self?.updates.append(RecordedReaderUpdate(update))
            }
        }
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
