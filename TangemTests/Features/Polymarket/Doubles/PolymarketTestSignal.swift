//
//  PolymarketTestSignal.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class PolymarketTestSignal<Event: Sendable>: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var recorded: [Event] {
        state.withLock { $0.recorded }
    }

    func send(_ event: Event) {
        let waiter = state.withLock { state -> CheckedContinuation<Event, Error>? in
            state.recorded.append(event)

            guard !state.waiters.isEmpty else {
                state.pending.append(event)
                return nil
            }

            return state.waiters.removeFirst().continuation
        }

        waiter?.resume(returning: event)
    }

    @MainActor
    @discardableResult
    func next() async throws -> Event {
        let id = UUID()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Event, Error>) in
                let outcome = state.withLock { state -> Result<Event, Error>? in
                    if Task.isCancelled {
                        return .failure(CancellationError())
                    }

                    guard state.pending.isEmpty else {
                        return .success(state.pending.removeFirst())
                    }

                    state.waiters.append(Waiter(id: id, continuation: continuation))
                    return nil
                }

                if let outcome {
                    continuation.resume(with: outcome)
                }
            }
        } onCancel: {
            let waiter = state.withLock { state -> CheckedContinuation<Event, Error>? in
                guard let index = state.waiters.firstIndex(where: { $0.id == id }) else { return nil }

                return state.waiters.remove(at: index).continuation
            }

            waiter?.resume(throwing: CancellationError())
        }
    }

    @MainActor
    @discardableResult
    func next(where isMatching: (Event) -> Bool) async throws -> Event {
        while true {
            let event = try await next()

            if isMatching(event) {
                return event
            }
        }
    }

    @MainActor
    func waitForCount(_ count: Int) async throws {
        while recorded.count < count {
            try await next()
        }
    }

    @discardableResult
    func record<Element>(_ stream: AsyncStream<Element>, transform: @escaping @Sendable (Element) -> Event) -> Task<Void, Never> {
        Task { [self] in
            for await element in stream {
                send(transform(element))
            }
        }
    }

    private struct State {
        var recorded: [Event] = []
        var pending: [Event] = []
        var waiters: [Waiter] = []
    }

    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<Event, Error>
    }
}

extension PolymarketTestSignal where Event == Void {
    func send() {
        send(())
    }
}

// MARK: - Gate

final class PolymarketTestGate: Sendable {
    let entered = PolymarketTestSignal<Void>()
    let cancelled = PolymarketTestSignal<Void>()

    private let state = OSAllocatedUnfairLock(initialState: State())

    var isOpen: Bool {
        state.withLock { $0.isOpen }
    }

    init(isOpen: Bool = false) {
        state.withLock { $0.isOpen = isOpen }
    }

    @MainActor
    func pass() async {
        entered.send()

        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let passesNow = state.withLock { state -> Bool in
                    guard !state.isOpen else { return true }

                    state.waiters.append(continuation)
                    return false
                }

                if passesNow {
                    continuation.resume()
                }
            }
        } onCancel: {
            cancelled.send()
        }
    }

    func open() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.isOpen = true
            defer { state.waiters.removeAll() }
            return state.waiters
        }

        waiters.forEach { $0.resume() }
    }

    func releaseWaiting() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            defer { state.waiters.removeAll() }
            return state.waiters
        }

        waiters.forEach { $0.resume() }
    }

    private struct State {
        var isOpen = false
        var waiters: [CheckedContinuation<Void, Never>] = []
    }
}
