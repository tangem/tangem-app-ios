//
//  PollingSubscription.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class PollingSubscription {
    private let isCancelled = OSAllocatedUnfairLock(initialState: false)
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    deinit {
        cancel()
    }

    func cancel() {
        let shouldCancel = isCancelled { isCancelled in
            guard !isCancelled else {
                return false
            }

            isCancelled = true

            return true
        }

        if shouldCancel {
            onCancel()
        }
    }
}
