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
public final class ResumableOnceCheckedContinuationWrapper<T, E>: @unchecked Sendable where E: Error {
    private let innerContinuation: CheckedContinuation<T, E>
    private let criticalSection = OSAllocatedUnfairLock()
    private var isResumed = false

    public init(_ innerContinuation: CheckedContinuation<T, E>) {
        self.innerContinuation = innerContinuation
    }

    /// Safe shim for `CheckedContinuation.resume(returning:)`.
    public func resumeIfNeeded(returning value: T) {
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
    public func resumeIfNeeded(throwing error: E) {
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

// MARK: - Convenience extensions

public extension ResumableOnceCheckedContinuationWrapper where T == Void {
    func resumeIfNeeded() {
        resumeIfNeeded(returning: ())
    }
}
