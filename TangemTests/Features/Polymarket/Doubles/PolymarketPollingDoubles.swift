//
//  PolymarketPollingDoubles.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class AppStateObserverStub: AppStateObserving {
    private var onChange: (@MainActor (Bool) -> Void)?

    func start(onChange: @escaping @MainActor (_ isInBackground: Bool) -> Void) {
        self.onChange = onChange
    }

    @MainActor
    func enterBackground() {
        onChange?(true)
    }

    @MainActor
    func enterForeground() {
        onChange?(false)
    }
}

final class ParkingDelayProvider: PollDelayProvider, Sendable {
    enum Event: Equatable, Sendable {
        case parked(TimeInterval)
        case cancelled(TimeInterval)
    }

    let events: AsyncStream<Event>

    private let continuation: AsyncStream<Event>.Continuation
    private let onEvent: @Sendable (Event) -> Void
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(onEvent: @escaping @Sendable (Event) -> Void = { _ in }) {
        (events, continuation) = AsyncStream.makeStream()
        self.onEvent = onEvent
    }

    func wait(for seconds: TimeInterval) async throws {
        let id = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (waiter: CheckedContinuation<Void, Error>) in
                let isCancelled = state.withLock { state -> Bool in
                    guard !Task.isCancelled else { return true }

                    state.parked.append(Parked(id: id, seconds: seconds, waiter: waiter))
                    return false
                }

                if isCancelled {
                    waiter.resume(throwing: CancellationError())
                } else {
                    report(.parked(seconds))
                }
            }
        } onCancel: {
            let parked = state.withLock { state -> Parked? in
                guard let index = state.parked.firstIndex(where: { $0.id == id }) else { return nil }

                return state.parked.remove(at: index)
            }

            guard let parked else { return }

            report(.cancelled(parked.seconds))
            parked.waiter.resume(throwing: CancellationError())
        }
    }

    func releaseParkedWaits() {
        let parked = state.withLock { state -> [Parked] in
            defer { state.parked.removeAll() }
            return state.parked
        }

        parked.forEach { $0.waiter.resume() }
    }

    private func report(_ event: Event) {
        onEvent(event)
        continuation.yield(event)
    }

    private struct State {
        var parked: [Parked] = []
    }

    private struct Parked {
        let id: UUID
        let seconds: TimeInterval
        let waiter: CheckedContinuation<Void, Error>
    }
}
