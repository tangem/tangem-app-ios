//
//  SingleTaskProcessorTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

@Suite("SingleTaskProcessor tests")
struct SingleTaskProcessorTests {
    @Test("Coalesces concurrent calls to a single task")
    func coalescesConcurrentCalls() async throws {
        let processor = SingleTaskProcessor<Int, SpecificError>()
        let counters = Counters()
        let values = Values(start: 1)

        let action = makeAction(values: values, counters: counters, delay: 150)

        async let result1: Int = processor.execute(action: action)
        async let result2: Int = processor.execute(action: action)
        async let result3: Int = processor.execute(action: action)

        let allResults = try await [result1, result2, result3]

        #expect(allResults == [1, 1, 1])
        let (starts, finishes) = await counters.snapshot()
        #expect(starts == 1)
        #expect(finishes == 1)
    }

    @Test("Late joiners share first result")
    func lateJoinersShareResult() async throws {
        let processor = SingleTaskProcessor<Int, SpecificError>()
        let counters = Counters()
        let values = Values(start: 10)

        let action = makeAction(values: values, counters: counters, delay: 200)

        async let result1: Int = processor.execute(action: action)

        // Joiners that arrive shortly after should still attach to the same in-flight task
        try await Task.sleep(for: .milliseconds(20))

        async let result2: Int = processor.execute(action: action)
        async let result3: Int = processor.execute(action: action)

        let allResults = try await [result1, result2, result3]
        #expect(allResults == [10, 10, 10])

        let (starts, finishes) = await counters.snapshot()
        #expect(starts == 1)
        #expect(finishes == 1)
    }

    @Test("Immediate restart creates a fresh task")
    func immediateRestartCreatesFreshTask() async throws {
        let processor = SingleTaskProcessor<Int, SpecificError>()
        let counters = Counters()
        let values = Values(start: 1)

        let action = makeAction(values: values, counters: counters, delay: 50)

        let firstResult = try await processor.execute(action: action)
        let secondResult = try await processor.execute(action: action)

        // Because the first finished, the second must be a new underlying run with the next value
        #expect(secondResult == firstResult + 1)

        let (starts, finishes) = await counters.snapshot()
        #expect(starts == 2)
        #expect(finishes == 2)
    }

    @Test("cancel() cancels current task and throws CancellationError")
    func cancelCancelsCurrentTask() async throws {
        let processor = SingleTaskProcessor<Int, SpecificError>()
        let counters = Counters()
        let values = Values(start: 0)

        // Long-running action so we have time to cancel
        let longAction = makeAction(values: values, counters: counters, delay: 500)

        // Start execution via processor
        let running = Task {
            try await processor.execute(action: longAction)
        }

        // Give it a moment to start and then cancel the processor
        try await Task.sleep(for: .milliseconds(50))
        await processor.cancel()

        // The awaiting caller should receive CancellationError
        do {
            _ = try await running.value
            Issue.record("Expected CancellationError from execute after cancel()")
        } catch SpecificError.cancel {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        // After cancellation, a new execute should start a fresh task and succeed
        let shortAction = makeAction(values: values, counters: counters, delay: 30)
        let recoveredValue = try await processor.execute(action: shortAction)
        #expect(recoveredValue == 1)

        let (starts, finishes) = await counters.snapshot()
        // We expect two starts: one for the canceled run, one for the fresh run.
        // Finishes must be one (the fresh run).
        #expect(starts == 2)
        #expect(finishes == 1)
    }

    @Test("Rethrows action error and recovers")
    func errorPropagationAndRecovery() async throws {
        let processor = SingleTaskProcessor<Int, SpecificError>()
        let counters = Counters()

        // First: should throw
        let throwing = { @Sendable () async throws(SpecificError) -> Int in
            await counters.start()
            do {
                try await Task.sleep(for: .milliseconds(30))
            } catch {
                throw .cancel
            }

            // No finish here because the action throws
            throw .boom
        }

        do {
            _ = try await processor.execute(action: throwing)
            Issue.record("Expected DummyError to be thrown")
        } catch .boom {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        // Second: should succeed (fresh task)
        let values = Values(start: 0)
        let successAction = makeAction(values: values, counters: counters, delay: 10)
        let result = try await processor.execute(action: successAction)
        #expect(result == 0)

        let (starts, finishes) = await counters.snapshot()
        // We expect two starts: one for the throwing run, one for the fresh run.
        // Finishes must be one (the fresh run).
        #expect(starts == 2)
        #expect(finishes == 1)
    }
}

// MARK: - Test helpers

extension SingleTaskProcessorTests {
    private actor Counters {
        private(set) var starts = 0
        private(set) var finishes = 0

        func start() { starts += 1 }
        func finish() { finishes += 1 }
        func snapshot() -> (starts: Int, finishes: Int) { (starts, finishes) }
    }

    private actor Values {
        private(set) var current: Int
        init(start: Int) { current = start }
        func next() -> Int { defer { current += 1 }; return current }
    }

    private enum SpecificError: Error {
        case cancel
        case boom
    }

    private func makeAction(values: Values, counters: Counters, delay milliseconds: Int) -> @Sendable () async throws(SpecificError) -> Int {
        return { () async throws(SpecificError) -> Int in
            await counters.start()
            let nextValue = await values.next()

            do {
                try await Task.sleep(for: .milliseconds(milliseconds))
                try Task.checkCancellation()
            } catch {
                throw .cancel
            }

            await counters.finish()
            return nextValue
        }
    }
}
