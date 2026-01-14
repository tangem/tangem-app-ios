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
    private let criticalSection = OSAllocatedUnfairLock()
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

        // This method may be called on a thread without a run loop (e.g., a background thread),
        // so the timer is scheduled on the main run loop manually (instead of using `Timer.scheduledTimer`)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] timer in
            self?.performWork()
        }
        RunLoop.main.add(timer, forMode: .common)
        unsafeTimer = timer
    }

    private func performWork() {
        let completions = criticalSection {
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
