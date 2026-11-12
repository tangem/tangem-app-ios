//
//  ThreadSafeCancellableSlotTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import TangemFoundation

@Suite("Thread-safe cancellable slot", .timeLimit(.minutes(1)))
struct ThreadSafeCancellableSlotTests {
    @Test("A cancellable stored for the current token stays alive until cancel()")
    func storedCancellableIsCancelledByCancel() {
        let sut = ThreadSafeCancellableSlot()
        let spy = CancellableSpy()

        let token = sut.begin()
        sut.store(AnyCancellable(spy), for: token)
        #expect(spy.cancelCount == 0)

        sut.cancel()
        #expect(spy.cancelCount == 1)
    }

    @Test("begin() cancels the previously stored cancellable")
    func beginCancelsPreviousCancellable() {
        let sut = ThreadSafeCancellableSlot()
        let previousSpy = CancellableSpy()
        let nextSpy = CancellableSpy()

        sut.store(AnyCancellable(previousSpy), for: sut.begin())
        let nextToken = sut.begin()
        #expect(previousSpy.cancelCount == 1)

        sut.store(AnyCancellable(nextSpy), for: nextToken)
        #expect(nextSpy.cancelCount == 0)
    }

    @Test("A cancellable stored for a token that a later begin() replaced is cancelled at once")
    func outdatedTokenCancelsImmediately() {
        let sut = ThreadSafeCancellableSlot()
        let outdatedSpy = CancellableSpy()
        let currentSpy = CancellableSpy()

        let outdatedToken = sut.begin()
        let currentToken = sut.begin()

        sut.store(AnyCancellable(currentSpy), for: currentToken)
        sut.store(AnyCancellable(outdatedSpy), for: outdatedToken)

        #expect(outdatedSpy.cancelCount == 1)
        #expect(currentSpy.cancelCount == 0)
    }

    @Test("A cancellable stored after cancel() is cancelled at once")
    func storeAfterCancelCancelsImmediately() {
        let sut = ThreadSafeCancellableSlot()
        let spy = CancellableSpy()

        let token = sut.begin()
        sut.cancel()
        sut.store(AnyCancellable(spy), for: token)

        #expect(spy.cancelCount == 1)
    }

    @Test("A second cancellable stored for the same token is cancelled at once and the first one is kept")
    func secondStoreForSameTokenCancelsImmediately() {
        let sut = ThreadSafeCancellableSlot()
        let firstSpy = CancellableSpy()
        let secondSpy = CancellableSpy()

        let token = sut.begin()
        sut.store(AnyCancellable(firstSpy), for: token)
        sut.store(AnyCancellable(secondSpy), for: token)

        #expect(firstSpy.cancelCount == 0)
        #expect(secondSpy.cancelCount == 1)
    }

    @Test("The slot accepts new cancellables after cancel()")
    func slotIsReusableAfterCancel() {
        let sut = ThreadSafeCancellableSlot()
        let spy = CancellableSpy()

        sut.cancel()
        sut.store(AnyCancellable(spy), for: sut.begin())
        #expect(spy.cancelCount == 0)

        sut.cancel()
        #expect(spy.cancelCount == 1)
    }

    @Test("AnyCancellable.store(in:for:) stores the cancellable like store(_:for:)")
    func storeInConvenience() {
        let sut = ThreadSafeCancellableSlot()
        let spy = CancellableSpy()

        AnyCancellable(spy).store(in: sut, for: sut.begin())
        #expect(spy.cancelCount == 0)

        sut.cancel()
        #expect(spy.cancelCount == 1)
    }

    @Test("Of two overlapping requests, the one that began last stays alive")
    func overlappingRequestsLeaveLatestAlive() async {
        let iterations = 500

        for _ in 0 ..< iterations {
            let sut = ThreadSafeCancellableSlot()
            let olderSpy = CancellableSpy()
            let newerSpy = CancellableSpy()
            let olderToken = sut.begin()

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    sut.store(AnyCancellable(olderSpy), for: olderToken)
                }

                group.addTask {
                    sut.store(AnyCancellable(newerSpy), for: sut.begin())
                }
            }

            #expect(olderSpy.cancelCount == 1)
            #expect(newerSpy.cancelCount == 0)

            sut.cancel()
            #expect(olderSpy.cancelCount == 1)
            #expect(newerSpy.cancelCount == 1)
        }
    }

    @Test("Concurrent store() and cancel() cancel the cancellable exactly once")
    func concurrentStoreAndCancelCancelExactlyOnce() async {
        let iterations = 500

        for _ in 0 ..< iterations {
            let sut = ThreadSafeCancellableSlot()
            let spy = CancellableSpy()
            let token = sut.begin()

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    sut.store(AnyCancellable(spy), for: token)
                }

                group.addTask {
                    sut.cancel()
                }
            }

            #expect(spy.cancelCount == 1)
        }
    }
}

// MARK: - Stubs

private extension ThreadSafeCancellableSlotTests {
    final class CancellableSpy: Cancellable, Sendable {
        private let count = OSAllocatedUnfairLock(initialState: 0)

        var cancelCount: Int {
            count { $0 }
        }

        func cancel() {
            count { $0 += 1 }
        }
    }
}
