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
final class ThreadSafeCancellableWrapper {
    private let criticalSection = OSAllocatedUnfairLock()
    private var innerCancellable: Cancellable?
    private var isCancelled = false

    init(_ innerCancellable: Cancellable? = nil) {
        self.innerCancellable = innerCancellable
    }

    func set(_ cancellable: Cancellable) {
        criticalSection {
            if isCancelled {
                cancellable.cancel()
            } else {
                innerCancellable = cancellable
            }
        }
    }

    func cancel() {
        criticalSection {
            isCancelled = true
            innerCancellable?.cancel()
            innerCancellable = nil
        }
    }
}

// MARK: - Convenience extensions

extension AnyCancellable {
    func store(in wrapper: ThreadSafeCancellableWrapper) {
        wrapper.set(self)
    }
}
