//
//  PollingSequence.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct PollingSequence<T>: AsyncSequence {
    typealias Request = () async throws -> T

    private let interval: TimeInterval
    private let request: Request
    private let delayProvider: PollDelayProvider

    init(
        interval: TimeInterval,
        request: @escaping Request,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.interval = interval
        self.request = request
        self.delayProvider = delayProvider
    }

    func makeAsyncIterator() -> Iterator {
        Iterator(interval: interval, request: request, delayProvider: delayProvider)
    }
}

extension PollingSequence {
    struct Iterator: AsyncIteratorProtocol {
        private let interval: TimeInterval
        private let request: Request
        private let delayProvider: PollDelayProvider
        private var isFirst = true

        init(interval: TimeInterval, request: @escaping Request, delayProvider: PollDelayProvider) {
            self.interval = interval
            self.request = request
            self.delayProvider = delayProvider
        }

        mutating func next() async -> Result<T, Error>? {
            guard !Task.isCancelled else { return nil }

            if !isFirst {
                try? await delayProvider.wait(for: interval)
            } else {
                isFirst = false
            }

            guard !Task.isCancelled else { return nil }

            do {
                let value = try await request()
                return .success(value)
            } catch {
                return .failure(error)
            }
        }
    }
}

protocol PollDelayProvider {
    func wait(for seconds: TimeInterval) async throws
}

struct TaskSleepPollDelayProvider: PollDelayProvider {
    func wait(for seconds: TimeInterval) async throws {
        try await Task.sleep(seconds: seconds)
    }
}

final class InstantPollDelayProvider: PollDelayProvider {
    private(set) var elapsed: TimeInterval = .zero

    func wait(for seconds: TimeInterval) async throws {
        elapsed += seconds
    }
}
