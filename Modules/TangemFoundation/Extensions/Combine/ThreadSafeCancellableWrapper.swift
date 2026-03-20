//
//  ThreadSafeCancellableWrapper.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// This wrapper provides required synchronization for the `Cancellable` object, so it can be safely cancelled only once from any thread.
/// Useful for the API like `withTaskCancellationHandler(operation:onCancel:)` when there is no guarantee which closure
/// (`operation` or `onCancel`) will be called first.
/// - Note: This wrapper uses internal synchronization, so it marked with `@unchecked Sendable`.
public final class ThreadSafeCancellableWrapper: @unchecked Sendable {
    private let criticalSection = OSAllocatedUnfairLock()
    private var innerCancellable: Cancellable?
    private var isCancelled = false

    public init(_ innerCancellable: Cancellable? = nil) {
        self.innerCancellable = innerCancellable
    }

    public func set(_ cancellable: Cancellable) {
        let shouldCancelImmediately: Bool = criticalSection {
            // This check is crucial since `self.set(_:)` can be called later than `self.cancel()`,
            // and in this case, the `cancellable` should be cancelled immediately.
            // `withTaskCancellationHandler(operation:onCancel:)` API provides no guarantees about the order of
            // `operation`/`onCancel` closures execution, so we need to handle both cases.
            // See https://developer.apple.com/documentation/swift/withtaskcancellationhandler(operation:oncancel:isolation:)
            // for more details.
            if isCancelled {
                // Fast path without setting `innerCancellable` since it will be cancelled immediately.
                return true
            }

            // Slow path, `innerCancellable` will be cancelled later in `self.cancel()`.
            innerCancellable = cancellable
            return false
        }

        // Cancellation should be performed outside of critical section to avoid potential deadlocks
        if shouldCancelImmediately {
            cancellable.cancel()
        }
    }

    public func cancel() {
        let cancellableToCancel: Cancellable? = criticalSection {
            isCancelled = true
            let cancellableToCancel = innerCancellable
            innerCancellable = nil
            return cancellableToCancel
        }

        // Cancellation should be performed outside of critical section to avoid potential deadlocks
        cancellableToCancel?.cancel()
    }
}

// MARK: - Convenience extensions

public extension AnyCancellable {
    func store(in wrapper: ThreadSafeCancellableWrapper) {
        wrapper.set(self)
    }
}
