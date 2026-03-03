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
public final class ThreadSafeCancellableWrapper {
    private let criticalSection = OSAllocatedUnfairLock()
    private var innerCancellable: Cancellable?
    private var isCancelled = false

    public init(_ innerCancellable: Cancellable? = nil) {
        self.innerCancellable = innerCancellable
    }

    public func set(_ cancellable: Cancellable) {
        criticalSection {
            // This check is crucial since `self.set(_:)` can be called later than `self.cancel()`,
            // and in this case, the `cancellable` should be cancelled immediately.
            // `withTaskCancellationHandler(operation:onCancel:)` API provides no guarantees about the order of
            // `operation`/`onCancel` closures execution, so we need to handle both cases.
            // See https://developer.apple.com/documentation/swift/withtaskcancellationhandler(operation:oncancel:isolation:)
            // for more details.
            if isCancelled {
                cancellable.cancel()
            } else {
                innerCancellable = cancellable
            }
        }
    }

    public func cancel() {
        criticalSection {
            isCancelled = true
            innerCancellable?.cancel()
            innerCancellable = nil
        }
    }
}

// MARK: - Convenience extensions

public extension AnyCancellable {
    func store(in wrapper: ThreadSafeCancellableWrapper) {
        wrapper.set(self)
    }
}
