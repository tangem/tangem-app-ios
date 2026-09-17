//
//  RepeatedTaskProcessor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Runs the action every `duration`, from `start` until `cancel`, one run at a time: the next wait is counted
/// from the end of the run before it, so two runs never overlap.
/// The first run waits out one `duration`, since whoever starts the processor has usually just done the work itself.
/// - Note: Stopping is the owner's to do, the way `SingleTaskProcessor` is stopped; an owner that goes away without
/// stopping it takes the loop with it, since nothing else is left to end it.
public actor RepeatedTaskProcessor {
    private let duration: Duration
    private var currentTask: Task<Void, Error>?

    /// - Note: What this says is whether the timer ticks; a run that does not shorten on cancellation may still be
    /// going after it turns `false`.
    public var isRunning: Bool {
        currentTask?.isCancelled == false
    }

    public init(duration: Duration) {
        self.duration = duration
    }

    deinit {
        // The loop holds nothing of the processor, so without this it would go on ticking after the owner is gone
        currentTask?.cancel()
    }

    /// Starts the timer, unless one is ticking already, in which case the action it was started with stays.
    public func start(action: @escaping @Sendable () async -> Void) {
        guard !isRunning else {
            return
        }

        // Read here rather than in the task, which would hold the processor and keep `deinit` from ever running
        let duration = duration

        currentTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: duration)
                // A cancellation arriving after the deadline has passed leaves the sleep to return as it would have
                try Task.checkCancellation()
                await action()
            }
        }
    }

    /// Stops the timer, and cancels the run that is going along with it — what that costs the run is its action's to say.
    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}
