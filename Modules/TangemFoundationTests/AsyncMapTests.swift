//
//  AsyncMapTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
@testable import TangemFoundation

@Suite("asyncMap() tests", .timeLimit(.minutes(1)))
struct AsyncMapTests {
    // MARK: - Delivery

    @Test("The output of a transform that returns without suspending is delivered")
    func deliversOutputOfNonSuspendingTransform() async {
        let failedIterations = await StressTest.failedIterations(count: Constants.iterationCount) { value in
            let recording = await Just(value)
                .asyncMap { $0 * 2 }
                .record()

            return recording.values == [value * 2]
        }

        #expect(failedIterations.isEmpty)
    }

    @Test("Every value of a synchronous upstream is delivered in the upstream order")
    func deliversEveryValueOfSynchronousUpstreamInOrder() async throws {
        let values = Array(0 ..< Constants.iterationCount)

        let recording = await values.publisher
            .asyncMap { $0 }
            .record()

        let lostValues = Set(values).subtracting(recording.values)
        try #require(lostValues.isEmpty)
        #expect(recording.values == values)
    }

    @Test("The output of a suspending transform is delivered")
    func deliversOutputOfSuspendingTransform() async {
        let transformStarted = TestSignal<Void>()
        let transformResumed = TestSignal<Void>()

        async let pendingRecording = Just(21)
            .asyncMap { value in
                transformStarted.fire()
                await transformResumed.wait()

                return value * 2
            }
            .record()

        await transformStarted.wait()
        transformResumed.fire()
        let recording = await pendingRecording

        #expect(recording.values == [42])
    }

    @Test("An empty upstream finishes without invoking the transform")
    func finishesWithoutInvokingTransformForEmptyUpstream() async {
        let invocationCount = OSAllocatedUnfairLock(initialState: 0)

        let recording = await Empty<Int, Never>()
            .asyncMap { value in
                invocationCount { $0 += 1 }

                return value
            }
            .record()

        #expect(recording.values.isEmpty)
        #expect(invocationCount { $0 } == 0)
    }

    @Test("An upstream failure is forwarded without invoking the transform")
    func forwardsUpstreamFailureWithoutInvokingTransform() async {
        let invocationCount = OSAllocatedUnfairLock(initialState: 0)

        let recording = await Fail<Int, String>(error: Constants.upstreamError)
            .asyncMap { value in
                invocationCount { $0 += 1 }

                return value
            }
            .record()

        #expect(recording.values.isEmpty)
        #expect(recording.error as? String == Constants.upstreamError)
        #expect(invocationCount { $0 } == 0)
    }

    // MARK: - Serialization

    @Test("Upstream values are transformed one at a time and delivered in the upstream order")
    func transformsUpstreamValuesOneAtATime() async {
        let values = [5, 4, 3, 2, 1]
        let concurrencyTracker = OSAllocatedUnfairLock(initialState: ConcurrencyTracker())
        let startedValues = TestSignal<Int>()
        let resumeSignals = Dictionary(uniqueKeysWithValues: values.map { ($0, TestSignal<Void>()) })

        async let pendingRecording = values.publisher
            .asyncMap { value in
                concurrencyTracker { $0.enter() }
                defer { concurrencyTracker { $0.leave() } }
                startedValues.fire(value)
                await resumeSignals[value]?.wait()

                return value
            }
            .record()

        for value in values {
            let startedValue = await startedValues.wait()
            #expect(startedValue == value)
            resumeSignals[value]?.fire()
        }

        let recording = await pendingRecording

        #expect(recording.values == values)
        #expect(concurrencyTracker { $0.maxActiveCount } == 1)
    }

    // MARK: - Cancellation

    @Test("Cancelling right after subscribing skips the transforms that haven't started yet")
    func cancellingBeforeTransformStartsSkipsIt() async {
        let invocationCount = OSAllocatedUnfairLock(initialState: 0)
        let releasedInputCount = OSAllocatedUnfairLock(initialState: 0)
        let allInputsReleased = TestSignal<Void>()

        for _ in 0 ..< Constants.iterationCount {
            let input = ReleaseProbe {
                let releasedCount = releasedInputCount { count in
                    count += 1

                    return count
                }

                if releasedCount == Constants.iterationCount {
                    allInputsReleased.fire()
                }
            }

            Just(input)
                .asyncMap { value in
                    invocationCount { $0 += 1 }

                    return value
                }
                .sink { _ in }
                .cancel()
        }

        await allInputsReleased.wait()

        #expect(invocationCount { $0 } < Constants.iterationCount)
    }

    @Test("Cancelling the subscription cancels the in-flight transform and stops the stream")
    func cancellingSubscriptionCancelsInFlightTransform() async {
        let transformStarted = TestSignal<Void>()
        let transformFinished = TestSignal<Bool>()
        let neverFiringSignal = TestSignal<Void>()
        let outputReleased = TestSignal<Void>()
        let transformedValues = OSAllocatedUnfairLock(initialState: [Int]())
        let deliveredEventCount = OSAllocatedUnfairLock(initialState: 0)

        let cancellable = [1, 2, 3].publisher
            .asyncMap { value in
                transformedValues { $0.append(value) }
                transformStarted.fire()
                defer { transformFinished.fire(Task.isCancelled) }
                await neverFiringSignal.wait()

                return ReleaseProbe {
                    outputReleased.fire()
                }
            }
            .sink(
                receiveCompletion: { _ in
                    deliveredEventCount { $0 += 1 }
                },
                receiveValue: { _ in
                    deliveredEventCount { $0 += 1 }
                }
            )

        await transformStarted.wait()
        cancellable.cancel()

        let isTransformCancelled = await transformFinished.wait()
        await outputReleased.wait()

        #expect(isTransformCancelled == true)
        #expect(transformedValues { $0 } == [1])
        #expect(deliveredEventCount { $0 } == 0)
    }
}

// MARK: - Constants

private enum Constants {
    static let iterationCount = 10_000
    static let upstreamError = "Upstream failure"
}
