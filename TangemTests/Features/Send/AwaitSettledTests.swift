//
//  AwaitSettledTests.swift
//  TangemTests
//
//  Created for [REDACTED_INFO].
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

/// Guards [REDACTED_INFO]: the send flows wait on the slot, not on the task they happened to read, so a rebuild
/// that replaces the awaited one still gets awaited before anything is dispatched. A cancelled caller,
/// on the other hand, stops re-arming: it no longer owns the flow it was waiting for.
@Suite("awaitSettled")
struct AwaitSettledTests {
    @Test("An empty slot returns immediately", .timeLimit(.minutes(1)))
    func emptySlotReturnsImmediately() async {
        let slot = OSAllocatedUnfairLock(initialState: Task<Void, Never>?.none)

        await awaitSettled { slot.withLock { $0 } }
    }

    @Test("A settled task is awaited to completion", .timeLimit(.minutes(1)))
    func singleTaskIsAwaited() async {
        let slot = OSAllocatedUnfairLock(initialState: Task<Void, Never>?.none)
        let gate = TestGate()
        let events = EventLog()

        slot.withLock { $0 = Task { await gate.wait(); events.append("task") } }

        let waiter = Task { await awaitSettled { slot.withLock { $0 } }; events.append("settled") }
        gate.open()
        await waiter.value

        #expect(events.values == ["task", "settled"])
    }

    @Test("A newer task replacing the awaited one keeps the caller waiting", .timeLimit(.minutes(1)))
    func replacementKeepsWaiting() async throws {
        let slot = OSAllocatedUnfairLock(initialState: Task<Void, Never>?.none)
        let firstGate = TestGate()
        let secondGate = TestGate()
        let slotWasRead = TestGate()
        let slotWasReadAgain = TestGate()
        let slotReads = OSAllocatedUnfairLock(initialState: 0)
        let events = EventLog()

        slot.withLock { $0 = Task { await firstGate.wait(); events.append("first") } }

        let waiter = Task {
            await awaitSettled {
                let task = slot.withLock { $0 }
                let reads = slotReads.withLock { reads -> Int in
                    reads += 1
                    return reads
                }

                if reads == 1 {
                    slotWasRead.open()
                } else {
                    slotWasReadAgain.open()
                }

                return task
            }

            events.append("settled")
        }

        // The replacement has to land while the caller is parked on the first task: reaching the slot later
        // would hand it the second task right away, leaving the re-await this test guards unexecuted.
        await slotWasRead.wait()

        slot.withLock { current in
            let superseded = current
            current = Task { await secondGate.wait(); events.append("second") }
            superseded?.cancel()
        }

        firstGate.open()

        // A caller that settled on the task it had already awaited never comes back to the slot, and this
        // wait hangs until the time limit kills the test.
        await slotWasReadAgain.wait()
        #expect(!events.values.contains("settled"))

        secondGate.open()
        await waiter.value

        // The cancelled first task wakes up anyway and appends whenever it gets scheduled, so its position
        // proves nothing. What pins the order down is the replacement: it appends before its awaiter does.
        let values = events.values
        let second = try #require(values.firstIndex(of: "second"))
        let settled = try #require(values.firstIndex(of: "settled"))
        #expect(second < settled)
    }

    @Test("A cancelled caller stops instead of picking up the replacement", .timeLimit(.minutes(1)))
    func cancelledCallerStopsWaiting() async {
        let slot = OSAllocatedUnfairLock(initialState: Task<Void, Never>?.none)
        let firstGate = TestGate()
        let secondGate = TestGate()
        let slotWasRead = TestGate()
        let events = EventLog()

        slot.withLock { $0 = Task { await firstGate.wait(); events.append("first") } }

        let waiter = Task {
            await awaitSettled {
                let task = slot.withLock { $0 }
                slotWasRead.open()
                return task
            }

            events.append("settled")
        }

        await slotWasRead.wait()
        waiter.cancel()

        // Held shut for the whole assertion: a caller that ignored its own cancellation would park on this
        // replacement until the time limit killed the test.
        slot.withLock { current in
            let superseded = current
            current = Task { await secondGate.wait(); events.append("second") }
            superseded?.cancel()
        }

        firstGate.open()
        await waiter.value

        #expect(events.values.contains("settled"))
        #expect(!events.values.contains("second"))

        secondGate.open()
    }
}

// MARK: - Helpers

private final class EventLog: @unchecked Sendable {
    private let state = OSAllocatedUnfairLock(initialState: [String]())

    var values: [String] { state.withLock { $0 } }

    func append(_ event: String) {
        state.withLock { $0.append(event) }
    }
}
