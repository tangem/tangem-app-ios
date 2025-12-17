//
//  PollingSequence.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct PollingSequence<T>: AsyncSequence {
    public typealias Request = () async throws -> T

    private let interval: TimeInterval
    private let request: Request
    private let delayProvider: PollDelayProvider

    public init(
        interval: TimeInterval,
        request: @escaping Request,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.interval = interval
        self.request = request
        self.delayProvider = delayProvider
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(interval: interval, request: request, delayProvider: delayProvider)
    }
}

public extension PollingSequence {
    actor Iterator: AsyncIteratorProtocol {
        private let interval: TimeInterval
        private let request: Request
        private let delayProvider: PollDelayProvider

        private var isFirst = true
        private var isCancelled = false

        init(interval: TimeInterval, request: @escaping Request, delayProvider: PollDelayProvider) {
            self.interval = interval
            self.request = request
            self.delayProvider = delayProvider
        }

        public func next() async -> Result<T, Error>? {
            if Task.isCancelled || isCancelled {
                isCancelled = true
                return nil
            }

            if isFirst {
                isFirst = false
            } else {
                try? await delayProvider.wait(for: interval)

                if Task.isCancelled || isCancelled {
                    isCancelled = true
                    return nil
                }
            }

            do {
                let value = try await request()

                if Task.isCancelled || isCancelled {
                    isCancelled = true
                    return nil
                }

                return .success(value)
            } catch is CancellationError {
                isCancelled = true
                return nil
            } catch {
                return .failure(error)
            }
        }
    }
}

public protocol PollDelayProvider {
    func wait(for seconds: TimeInterval) async throws
}

public struct TaskSleepPollDelayProvider: PollDelayProvider {
    public init() {}

    public func wait(for seconds: TimeInterval) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }
}

public actor InstantPollDelayProvider: PollDelayProvider {
    private(set) var elapsed: TimeInterval = .zero

    public init() {}

    public func wait(for seconds: TimeInterval) async throws {
        elapsed += seconds
    }
}
