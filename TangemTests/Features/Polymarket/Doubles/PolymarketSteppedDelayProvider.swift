//
//  PolymarketSteppedDelayProvider.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class PolymarketSteppedDelayProvider: PollDelayProvider, Sendable {
    enum Event: Equatable, Sendable {
        case parked(TimeInterval)
        case cancelled(TimeInterval)
    }

    let requests = PolymarketTestSignal<TimeInterval>()
    let cancellations = PolymarketTestSignal<TimeInterval>()

    private let passes: @Sendable (TimeInterval) -> Bool
    private let onEvent: @Sendable (Event) -> Void
    private let state = OSAllocatedUnfairLock(initialState: State())

    var parkedWaits: [TimeInterval] {
        state.withLock { $0.parked.map(\.seconds) }
    }

    init(
        passing passes: @escaping @Sendable (TimeInterval) -> Bool = { _ in false },
        onEvent: @escaping @Sendable (Event) -> Void = { _ in }
    ) {
        self.passes = passes
        self.onEvent = onEvent
    }

    @MainActor
    func wait(for seconds: TimeInterval) async throws {
        guard !passes(seconds) else {
            try Task.checkCancellation()
            return
        }

        let id = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let isCancelled = state.withLock { state -> Bool in
                    guard !Task.isCancelled else { return true }

                    state.parked.append(Parked(id: id, seconds: seconds, continuation: continuation))
                    return false
                }

                if isCancelled {
                    continuation.resume(throwing: CancellationError())
                } else {
                    onEvent(.parked(seconds))
                    requests.send(seconds)
                }
            }
        } onCancel: {
            let parked = state.withLock { state -> Parked? in
                guard let index = state.parked.firstIndex(where: { $0.id == id }) else { return nil }

                return state.parked.remove(at: index)
            }

            if let parked {
                onEvent(.cancelled(parked.seconds))
                parked.continuation.resume(throwing: CancellationError())
                cancellations.send(parked.seconds)
            }
        }
    }

    @MainActor
    func waitUntilParked(_ seconds: TimeInterval) async throws {
        while !parkedWaits.contains(seconds) {
            try await requests.next()
        }
    }

    @MainActor
    @discardableResult
    func nextWait(of seconds: TimeInterval? = nil) async throws -> TimeInterval {
        try await requests.next { seconds == nil || $0 == seconds }
    }

    func resume(_ seconds: TimeInterval? = nil) {
        let resumed = state.withLock { state -> [Parked] in
            let resumed = state.parked.filter { seconds == nil || $0.seconds == seconds }
            state.parked.removeAll { seconds == nil || $0.seconds == seconds }
            return resumed
        }

        resumed.forEach { $0.continuation.resume() }
    }

    private struct State {
        var parked: [Parked] = []
    }

    private struct Parked {
        let id: UUID
        let seconds: TimeInterval
        let continuation: CheckedContinuation<Void, Error>
    }
}
