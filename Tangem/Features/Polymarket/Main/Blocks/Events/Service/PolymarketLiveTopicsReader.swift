//
//  PolymarketLiveTopicsReader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket

@MainActor
final class PolymarketLiveTopicsReader<Topic: Hashable & Sendable, Value: Sendable> {
    let updates: AsyncStream<Update>

    private let values: @Sendable (Set<Topic>) async -> AsyncStream<Value>
    private let updatesContinuation: AsyncStream<Update>.Continuation

    private(set) var trackedTopics: Set<Topic> = []
    private var readingTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?
    private var isConnected = false
    private var hasLostConnection = false
    private var isPaused = false

    init(
        values: @escaping @Sendable (Set<Topic>) async -> AsyncStream<Value>,
        statusChanges: @escaping @Sendable () async -> AsyncStream<PolymarketWebSocketConnectionStatus>
    ) {
        self.values = values
        (updates, updatesContinuation) = AsyncStream.makeStream(of: Update.self)

        statusTask = Task { [weak self] in
            for await status in await statusChanges() {
                self?.connectionStatusChanged(status)
            }
        }
    }

    deinit {
        readingTask?.cancel()
        statusTask?.cancel()
        updatesContinuation.finish()
    }

    func track(_ topics: Set<Topic>) {
        guard !isPaused, topics != trackedTopics else {
            return
        }

        trackedTopics = topics
        startReading(for: topics)
    }

    func pause() {
        isPaused = true
        trackedTopics = []
        startReading(for: [])
    }

    func resume() {
        isPaused = false
    }
}

// MARK: - Update

extension PolymarketLiveTopicsReader {
    enum Update: Sendable {
        case value(Value)
        case connectionLost
        case reconnected
    }
}

// MARK: - Private

private extension PolymarketLiveTopicsReader {
    func startReading(for topics: Set<Topic>) {
        let previousTask = readingTask

        guard !topics.isEmpty else {
            previousTask?.cancel()
            readingTask = nil
            return
        }

        readingTask = Task { [weak self, values] in
            let stream = await values(topics)
            previousTask?.cancel()

            for await value in stream {
                guard !Task.isCancelled else {
                    return
                }

                self?.updatesContinuation.yield(.value(value))
            }
        }
    }

    func connectionStatusChanged(_ status: PolymarketWebSocketConnectionStatus) {
        guard status != .connected else {
            isConnected = true

            if hasLostConnection {
                hasLostConnection = false
                updatesContinuation.yield(.reconnected)
            }

            return
        }

        guard isConnected else {
            return
        }

        isConnected = false
        hasLostConnection = status != .idle
        readingTask?.cancel()
        readingTask = nil

        if status != .stopped {
            startReading(for: trackedTopics)
        }

        updatesContinuation.yield(.connectionLost)
    }
}
