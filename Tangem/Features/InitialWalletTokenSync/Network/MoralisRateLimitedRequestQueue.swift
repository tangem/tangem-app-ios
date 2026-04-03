//
//  MoralisRateLimitedRequestQueue.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

/// Limits the number of concurrently executing async operations.
///
/// At most `maxConcurrentRequests` operations run at the same time.
/// Callers that exceed the limit suspend until a slot becomes available.
actor MoralisRateLimitedRequestQueue {
    private let maxConcurrentRequests: Int
    private var activeCount = 0
    private var waiters: [(id: UUID, continuation: CheckedContinuation<Void, Error>)] = []

    init(maxConcurrentRequests: Int = 3) {
        self.maxConcurrentRequests = maxConcurrentRequests
    }

    func execute<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        try await acquireSlot()
        defer { releaseSlot() }
        return try await operation()
    }

    // MARK: - Private

    private func acquireSlot() async throws {
        try Task.checkCancellation()

        if activeCount < maxConcurrentRequests {
            activeCount += 1
            return
        }

        let waiterID = UUID()
        try await suspendUntilSlotAvailable(waiterID: waiterID)

        try Task.checkCancellation()
        activeCount += 1
    }

    private func releaseSlot() {
        guard activeCount > 0 else { return }

        activeCount -= 1
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.continuation.resume(returning: ())
        }
    }

    private func cancelWaiter(id: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
        let waiter = waiters.remove(at: index)
        waiter.continuation.resume(throwing: CancellationError())
    }

    private func suspendUntilSlotAvailable(waiterID: UUID) async throws {
        try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    waiters.append((waiterID, continuation))
                }
            },
            onCancel: {
                Task {
                    await self.cancelWaiter(id: waiterID)
                }
            }
        )
    }
}
