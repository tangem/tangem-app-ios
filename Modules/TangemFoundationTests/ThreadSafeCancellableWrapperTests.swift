//
//  ThreadSafeCancellableWrapperTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import TangemFoundation

@Suite("ThreadSafeCancellableWrapper tests")
struct ThreadSafeCancellableWrapperTests {
    @Test("set() stores cancellable and cancel() cancels it")
    func setThenCancel() {
        let spy = CancellableSpy()
        let wrapper = ThreadSafeCancellableWrapper()

        wrapper.set(spy)
        #expect(spy.cancelCount == 0)

        wrapper.cancel()
        #expect(spy.cancelCount == 1)
    }

    @Test("cancel() before set() cancels the cancellable immediately on set()")
    func cancelBeforeSet() {
        let spy = CancellableSpy()
        let wrapper = ThreadSafeCancellableWrapper()

        wrapper.cancel()
        #expect(spy.cancelCount == 0)

        wrapper.set(spy)
        #expect(spy.cancelCount == 1)
    }

    @Test("cancel() without a stored cancellable does not crash")
    func cancelWithoutStoredCancellable() {
        let wrapper = ThreadSafeCancellableWrapper()
        wrapper.cancel()
    }

    @Test("Multiple cancel() calls cancel the inner cancellable only once")
    func multipleCancelsOnlyOnce() {
        let spy = CancellableSpy()
        let wrapper = ThreadSafeCancellableWrapper()

        wrapper.set(spy)
        wrapper.cancel()
        wrapper.cancel()
        wrapper.cancel()

        #expect(spy.cancelCount == 1)
    }

    @Test("set() after cancel() cancels each subsequent cancellable immediately")
    func setAfterCancelCancelsImmediately() {
        let wrapper = ThreadSafeCancellableWrapper()
        wrapper.cancel()

        let spy1 = CancellableSpy()
        wrapper.set(spy1)
        #expect(spy1.cancelCount == 1)

        let spy2 = CancellableSpy()
        wrapper.set(spy2)
        #expect(spy2.cancelCount == 1)
    }

    @Test("set() replaces previous cancellable without cancelling it")
    func setReplacesPrevious() {
        let spy1 = CancellableSpy()
        let spy2 = CancellableSpy()
        let wrapper = ThreadSafeCancellableWrapper()

        wrapper.set(spy1)
        wrapper.set(spy2)

        wrapper.cancel()

        #expect(spy1.cancelCount == 0)
        #expect(spy2.cancelCount == 1)
    }

    @Test("init(_:) stores the cancellable and cancel() cancels it")
    func initWithCancellable() {
        let spy = CancellableSpy()
        let wrapper = ThreadSafeCancellableWrapper(spy)

        wrapper.cancel()
        #expect(spy.cancelCount == 1)
    }

    @Test("AnyCancellable.store(in:) convenience works like set()")
    func storeInConvenience() {
        let spy = CancellableSpy()
        let anyCancellable = AnyCancellable(spy.cancel)
        let wrapper = ThreadSafeCancellableWrapper()

        anyCancellable.store(in: wrapper)
        wrapper.cancel()

        #expect(spy.cancelCount == 1)
    }

    @Test("Concurrent set() and cancel() do not crash and cancel exactly once")
    func concurrentSetAndCancel() async {
        let iterations = 500

        for _ in 0 ..< iterations {
            let spy = CancellableSpy()
            let wrapper = ThreadSafeCancellableWrapper()

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    wrapper.set(spy)
                }

                group.addTask {
                    wrapper.cancel()
                }
            }

            #expect(spy.cancelCount <= 1)
        }
    }

    @Test("Concurrent cancel() calls cancel inner cancellable at most once")
    func concurrentCancels() async {
        let iterations = 500

        for _ in 0 ..< iterations {
            let spy = CancellableSpy()
            let wrapper = ThreadSafeCancellableWrapper()
            wrapper.set(spy)

            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< 10 {
                    group.addTask {
                        wrapper.cancel()
                    }
                }
            }

            #expect(spy.cancelCount == 1)
        }
    }
}

// MARK: - Test helpers

private extension ThreadSafeCancellableWrapperTests {
    final class CancellableSpy: Cancellable, @unchecked Sendable {
        private let criticalSection = OSAllocatedUnfairLock()
        private var _cancelCount = 0

        var cancelCount: Int {
            criticalSection { _cancelCount }
        }

        func cancel() {
            criticalSection.withLock { _cancelCount += 1 }
        }
    }
}
