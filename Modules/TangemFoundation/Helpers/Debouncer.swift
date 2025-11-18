//
//  Debouncer.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
public final class Debouncer<T> {
    public typealias Completion = (_ result: T) -> Void
    public typealias Work = (_ completion: @escaping Completion) -> Void

    private let interval: TimeInterval
    private let work: Work
    private let criticalSection = Lock(isRecursive: false)
    private var unsafeCompletionBlocks: [Completion] = []
    private var unsafeTimer: Timer?

    public init(
        interval: TimeInterval,
        work: @escaping Work
    ) {
        self.interval = interval
        self.work = work
    }

    public func debounce(withCompletion completion: @escaping Completion) {
        criticalSection {
            unsafeCompletionBlocks.append(completion)
            unsafeScheduleTimer()
        }
    }

    private func unsafeScheduleTimer() {
        unsafeTimer?.invalidate()
        unsafeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] timer in
            self?.performWork()
        }
    }

    private func performWork() {
        let completions = criticalSection {
            unsafeTimer = nil // Just a resource cleanup, timer is already invalidated at this stage
            let completions = self.unsafeCompletionBlocks
            self.unsafeCompletionBlocks.removeAll()
            return completions
        }

        guard completions.isNotEmpty else {
            return
        }

        work { result in
            completions.forEach { $0(result) }
        }
    }
}
