//
//  AsyncTestSupport.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
@testable import TangemFoundation

// MARK: - Publisher recording

struct PublisherRecording<Output: Sendable>: Sendable {
    let values: [Output]
    let error: (any Error)?
}

extension Publisher where Output: Sendable {
    func record() async -> PublisherRecording<Output> {
        let values = OSAllocatedUnfairLock(initialState: [Output]())
        let subscription = OSAllocatedUnfairLock<AnyCancellable?>(uncheckedState: nil)

        return await withCheckedContinuation { continuation in
            let cancellable = sink(
                receiveCompletion: { completion in
                    let error: (any Error)? = switch completion {
                    case .finished:
                        nil
                    case .failure(let failure):
                        failure
                    }
                    continuation.resume(returning: PublisherRecording(values: values { $0 }, error: error))
                    subscription { $0 = nil }
                },
                receiveValue: { value in
                    values { $0.append(value) }
                }
            )
            subscription { $0 = cancellable }
        }
    }
}

// MARK: - Signal

struct TestSignal<Value: Sendable>: Sendable {
    private let stream: AsyncStream<Value>
    private let continuation: AsyncStream<Value>.Continuation

    init() {
        let (stream, continuation) = AsyncStream<Value>.makeStream()
        self.stream = stream
        self.continuation = continuation
    }

    func fire(_ value: Value) {
        continuation.yield(value)
    }

    func wait() async -> Value? {
        for await value in stream {
            return value
        }

        return nil
    }
}

extension TestSignal where Value == Void {
    func fire() {
        fire(())
    }
}

// MARK: - Concurrency tracking

struct ConcurrencyTracker: Sendable {
    private(set) var activeCount = 0
    private(set) var maxActiveCount = 0

    mutating func enter() {
        activeCount += 1
        maxActiveCount = max(maxActiveCount, activeCount)
    }

    mutating func leave() {
        activeCount -= 1
    }
}

// MARK: - Release tracking

final class ReleaseProbe: Error {
    private let onRelease: @Sendable () -> Void

    init(onRelease: @escaping @Sendable () -> Void) {
        self.onRelease = onRelease
    }

    deinit {
        onRelease()
    }
}

// MARK: - Stress testing

enum StressTest {
    static func failedIterations(
        count: Int,
        _ iteration: @escaping @Sendable (_ index: Int) async -> Bool
    ) async -> [Int] {
        let workerCount = ProcessInfo.processInfo.activeProcessorCount

        return await withTaskGroup(of: [Int].self) { group in
            for worker in 0 ..< workerCount {
                group.addTask {
                    var failedIndices: [Int] = []

                    for index in stride(from: worker, to: count, by: workerCount) {
                        if await !iteration(index) {
                            failedIndices.append(index)
                        }
                    }

                    return failedIndices
                }
            }

            return await group.reduce(into: [Int]()) { $0 += $1 }
        }
    }
}
