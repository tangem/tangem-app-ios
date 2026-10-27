//
//  AsyncTryMapTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
@testable import TangemFoundation

@Suite("asyncTryMap() tests", .timeLimit(.minutes(1)))
struct AsyncTryMapTests {
    // MARK: - Delivery

    @Test("The output of a transform that returns without suspending is delivered")
    func deliversOutputOfNonSuspendingTransform() async {
        let failedIterations = await StressTest.failedIterations(count: Constants.iterationCount) { value in
            let recording = await Just(value)
                .setFailureType(to: (any Error).self)
                .asyncTryMap { $0 * 2 }
                .record()

            return recording.values == [value * 2] && recording.error == nil
        }

        #expect(failedIterations.isEmpty)
    }

    @Test("An error thrown by a transform without suspending is delivered")
    func deliversErrorThrownWithoutSuspending() async {
        let failedIterations = await StressTest.failedIterations(count: Constants.iterationCount) { value in
            let recording = await Just(value)
                .setFailureType(to: (any Error).self)
                .asyncTryMap { _ -> Int in
                    throw Constants.transformError
                }
                .record()

            return recording.values.isEmpty && recording.error as? String == Constants.transformError
        }

        #expect(failedIterations.isEmpty)
    }

    @Test("Every value of a synchronous upstream is delivered in the upstream order")
    func deliversEveryValueOfSynchronousUpstreamInOrder() async throws {
        let values = Array(0 ..< Constants.iterationCount)

        let recording = await values.publisher
            .setFailureType(to: (any Error).self)
            .asyncTryMap { $0 }
            .record()

        let lostValues = Set(values).subtracting(recording.values)
        try #require(lostValues.isEmpty)
        #expect(recording.values == values)
        #expect(recording.error == nil)
    }

    @Test("The output of a suspending transform is delivered")
    func deliversOutputOfSuspendingTransform() async {
        let transformStarted = TestSignal<Void>()
        let transformResumed = TestSignal<Void>()

        async let pendingRecording = Just(21)
            .setFailureType(to: (any Error).self)
            .asyncTryMap { value in
                transformStarted.fire()
                await transformResumed.wait()

                return value * 2
            }
            .record()

        await transformStarted.wait()
        transformResumed.fire()
        let recording = await pendingRecording

        #expect(recording.values == [42])
        #expect(recording.error == nil)
    }

    @Test("An error thrown by a suspending transform is delivered")
    func deliversErrorThrownAfterSuspending() async {
        let transformStarted = TestSignal<Void>()
        let transformResumed = TestSignal<Void>()

        async let pendingRecording = Just(1)
            .setFailureType(to: (any Error).self)
            .asyncTryMap { _ -> Int in
                transformStarted.fire()
                await transformResumed.wait()
                throw Constants.transformError
            }
            .record()

        await transformStarted.wait()
        transformResumed.fire()
        let recording = await pendingRecording

        #expect(recording.values.isEmpty)
        #expect(recording.error as? String == Constants.transformError)
    }

    @Test("An empty upstream finishes without invoking the transform")
    func finishesWithoutInvokingTransformForEmptyUpstream() async {
        let invocationCount = OSAllocatedUnfairLock(initialState: 0)

        let recording = await Empty<Int, any Error>()
            .asyncTryMap { value in
                invocationCount { $0 += 1 }

                return value
            }
            .record()

        #expect(recording.values.isEmpty)
        #expect(recording.error == nil)
        #expect(invocationCount { $0 } == 0)
    }

    @Test("An upstream failure is forwarded without invoking the transform")
    func forwardsUpstreamFailureWithoutInvokingTransform() async {
        let invocationCount = OSAllocatedUnfairLock(initialState: 0)

        let recording = await Fail<Int, any Error>(error: Constants.upstreamError)
            .asyncTryMap { value in
                invocationCount { $0 += 1 }

                return value
            }
            .record()

        #expect(recording.values.isEmpty)
        #expect(recording.error as? String == Constants.upstreamError)
        #expect(invocationCount { $0 } == 0)
    }

    @Test("A thrown error terminates the stream, so later upstream values are not transformed")
    func thrownErrorTerminatesStream() async {
        let transformedValues = OSAllocatedUnfairLock(initialState: [Int]())

        let recording = await [1, 2, 3].publisher
            .setFailureType(to: (any Error).self)
            .asyncTryMap { value in
                transformedValues { $0.append(value) }

                if value == 2 {
                    throw Constants.transformError
                }

                return value
            }
            .record()

        #expect(recording.values == [1])
        #expect(recording.error as? String == Constants.transformError)
        #expect(transformedValues { $0 } == [1, 2])
    }

    // MARK: - Serialization

    @Test("Upstream values are transformed one at a time and delivered in the upstream order")
    func transformsUpstreamValuesOneAtATime() async {
        let values = [5, 4, 3, 2, 1]
        let concurrencyTracker = OSAllocatedUnfairLock(initialState: ConcurrencyTracker())
        let startedValues = TestSignal<Int>()
        let resumeSignals = Dictionary(uniqueKeysWithValues: values.map { ($0, TestSignal<Void>()) })

        async let pendingRecording = values.publisher
            .setFailureType(to: (any Error).self)
            .asyncTryMap { value in
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
        #expect(recording.error == nil)
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
                .setFailureType(to: (any Error).self)
                .asyncTryMap { value in
                    invocationCount { $0 += 1 }

                    return value
                }
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .cancel()
        }

        await allInputsReleased.wait()

        #expect(invocationCount { $0 } < Constants.iterationCount)
    }

    @Test("Cancelling the subscription cancels the in-flight transform without delivering the error it then throws")
    func cancellingSubscriptionCancelsInFlightTransform() async {
        let transformStarted = TestSignal<Void>()
        let transformFinished = TestSignal<Bool>()
        let neverFiringSignal = TestSignal<Void>()
        let errorReleased = TestSignal<Void>()
        let transformedValues = OSAllocatedUnfairLock(initialState: [Int]())
        let deliveredEventCount = OSAllocatedUnfairLock(initialState: 0)

        let cancellable = [1, 2, 3].publisher
            .setFailureType(to: (any Error).self)
            .asyncTryMap { value -> Int in
                transformedValues { $0.append(value) }
                transformStarted.fire()
                defer { transformFinished.fire(Task.isCancelled) }
                await neverFiringSignal.wait()

                throw ReleaseProbe {
                    errorReleased.fire()
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
        await errorReleased.wait()

        #expect(isTransformCancelled == true)
        #expect(transformedValues { $0 } == [1])
        #expect(deliveredEventCount { $0 } == 0)
    }
}

// MARK: - Constants

private enum Constants {
    static let iterationCount = 10_000
    static let upstreamError = "Upstream failure"
    static let transformError = "Transform failure"
}
