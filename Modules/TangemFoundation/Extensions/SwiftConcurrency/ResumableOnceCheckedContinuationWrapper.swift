//
//  ResumableOnceCheckedContinuationWrapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Resumes the given checked continuation exactly once.
/// - Note: This wrapper uses internal synchronization, so it marked with `@unchecked Sendable`.
final class ResumableOnceCheckedContinuationWrapper<T, E>: @unchecked Sendable where E: Error {
    private let innerContinuation: CheckedContinuation<T, E>
    private let criticalSection = OSAllocatedUnfairLock()
    private var isResumed = false

    init(_ innerContinuation: CheckedContinuation<T, E>) {
        self.innerContinuation = innerContinuation
    }

    /// Safe shim for `CheckedContinuation.resume(returning:)`.
    func resumeIfNeeded(returning value: T) {
        let continuationToResume: CheckedContinuation<T, E>? = criticalSection {
            if isResumed {
                return nil
            }

            isResumed = true
            return innerContinuation
        }

        // Resuming should be performed outside of critical section to avoid potential deadlocks
        continuationToResume?.resume(returning: value)
    }

    /// Safe shim for `CheckedContinuation.resume(throwing:)`.
    func resumeIfNeeded(throwing error: E) {
        let continuationToResume: CheckedContinuation<T, E>? = criticalSection {
            if isResumed {
                return nil
            }

            isResumed = true
            return innerContinuation
        }

        // Resuming should be performed outside of critical section to avoid potential deadlocks
        continuationToResume?.resume(throwing: error)
    }
}
