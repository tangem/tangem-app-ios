//
//  KeyedTaskProcessorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("KeyedTaskProcessorTests", .timeLimit(.minutes(1)))
struct KeyedTaskProcessorTests {
    @Test("Callers on the same key share one task")
    func coalescesCallsOnTheSameKey() async throws {
        let processor = KeyedTaskProcessor<RecordingKey, Int>()
        let gate = Gate()
        let counters = Counters()
        let keys = [RecordingKey("a"), RecordingKey("a"), RecordingKey("a")]

        @Sendable
        func call(with key: RecordingKey, returning value: Int) async throws -> Int {
            try await processor.execute(forKey: key) {
                await counters.start()
                await gate.wait()
                return value
            }
        }

        async let first = call(with: keys[0], returning: 1)
        async let second = call(with: keys[1], returning: 2)
        async let third = call(with: keys[2], returning: 3)

        // Held open until every caller is in, so a late caller cannot start a task of its own
        while !keys.allSatisfy(\.isLookedUp) {
            await Task.yield()
        }
        await gate.open()

        let results = try await [first, second, third]

        #expect(Set(results).count == 1)
        #expect(await counters.starts == 1)
    }

    @Test("Different keys run their own task")
    func runsDifferentKeysSeparately() async throws {
        let processor = KeyedTaskProcessor<String, Int>()
        let counters = Counters()

        async let first: Int = processor.execute(forKey: "a") { await counters.start(); return 1 }
        async let second: Int = processor.execute(forKey: "b") { await counters.start(); return 2 }

        let results = try await [first, second]

        #expect(results == [1, 2])
        #expect(await counters.starts == 2)
    }

    @Test("A failed key is cleared, so the next caller starts a fresh task")
    func clearsTheKeyAfterFailure() async throws {
        let processor = KeyedTaskProcessor<String, Int>()
        let counters = Counters()

        await #expect(throws: SpecificError.boom) {
            try await processor.execute(forKey: "a") { await counters.start(); throw SpecificError.boom }
        }

        let recovered = try await processor.execute(forKey: "a") { await counters.start(); return 7 }

        #expect(recovered == 7)
        #expect(await counters.starts == 2)
    }

    @Test("Joiners receive the error of the task they joined")
    func joinersReceiveTheSharedFailure() async throws {
        let processor = KeyedTaskProcessor<RecordingKey, Int>()
        let gate = Gate()
        let counters = Counters()
        let joinerKey = RecordingKey("a")

        let first = Task {
            try await processor.execute(forKey: RecordingKey("a")) { () async throws -> Int in
                await counters.start()
                await gate.wait()
                throw SpecificError.boom
            }
        }

        while await counters.starts == 0 {
            await Task.yield()
        }

        let second = Task {
            try await processor.execute(forKey: joinerKey) { 1 }
        }

        while !joinerKey.isLookedUp {
            await Task.yield()
        }
        await gate.open()

        await #expect(throws: SpecificError.boom) { try await first.value }
        await #expect(throws: SpecificError.boom) { try await second.value }
    }
}

// MARK: - Helpers

extension KeyedTaskProcessorTests {
    private actor Gate {
        private var isOpen = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        func wait() async {
            guard !isOpen else { return }

            await withCheckedContinuation { waiters.append($0) }
        }

        func open() {
            isOpen = true
            waiters.forEach { $0.resume() }
            waiters.removeAll()
        }
    }

    private actor Counters {
        private(set) var starts = 0

        func start() { starts += 1 }
    }

    private struct RecordingKey: Hashable, Sendable {
        private let lookup = OSAllocatedUnfairLock(initialState: false)

        let name: String

        init(_ name: String) {
            self.name = name
        }

        var isLookedUp: Bool {
            lookup.withLock { $0 }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }

        func hash(into hasher: inout Hasher) {
            lookup.withLock { $0 = true }
            hasher.combine(name)
        }
    }

    private enum SpecificError: Error {
        case boom
    }
}
