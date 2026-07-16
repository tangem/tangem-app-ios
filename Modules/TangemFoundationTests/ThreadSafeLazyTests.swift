//
//  ThreadSafeLazyTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import os.lock
@testable import TangemFoundation

@Suite
struct ThreadSafeLazyTests {
    @Test
    func cachesValueAndInvokesFactoryOnce() {
        let invocations = OSAllocatedUnfairLock(initialState: 0)
        let lazy = ThreadSafeLazy<Box> {
            invocations.withLock { $0 += 1 }
            return Box()
        }

        let first = lazy.value
        let second = lazy.value

        #expect(first === second)
        #expect(invocations.withLock { $0 } == 1)
    }

    @Test
    func cachesNilWhenValueIsOptionalAndFactoryReturnsNil() {
        let invocations = OSAllocatedUnfairLock(initialState: 0)
        let lazy = ThreadSafeLazy<Int?> {
            invocations.withLock { $0 += 1 }
            return nil
        }

        #expect(lazy.value == nil)
        #expect(lazy.value == nil)
        #expect(invocations.withLock { $0 } == 1)
    }

    @Test
    func concurrentFirstAccessInvokesFactoryOnce() async {
        let invocations = OSAllocatedUnfairLock(initialState: 0)
        nonisolated(unsafe) let lazy = ThreadSafeLazy<Box> {
            invocations.withLock { $0 += 1 }
            return Box()
        }

        let identifiers = await withTaskGroup(of: ObjectIdentifier.self) { group in
            for _ in 0 ..< 1000 {
                group.addTask { ObjectIdentifier(lazy.value) }
            }

            var result: Set<ObjectIdentifier> = []
            for await identifier in group {
                result.insert(identifier)
            }
            return result
        }

        #expect(identifiers.count == 1)
        #expect(invocations.withLock { $0 } == 1)
    }
}

private final class Box: Sendable {}
