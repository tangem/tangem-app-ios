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
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(maxConcurrentRequests: Int = 3) {
        self.maxConcurrentRequests = maxConcurrentRequests
    }

    func execute<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        await acquireSlot()
        do {
            let result = try await operation()
            releaseSlot()
            return result
        } catch {
            releaseSlot()
            throw error
        }
    }

    // MARK: - Private

    private func acquireSlot() async {
        if activeCount < maxConcurrentRequests {
            activeCount += 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
        activeCount += 1
    }

    private func releaseSlot() {
        activeCount -= 1
        if !waiters.isEmpty {
            waiters.removeFirst().resume()
        }
    }
}
