//
//  SlideStallGuard.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Skips a slide whose playback makes no progress across a full timeout window, at start or
/// mid-play. Buffering — a stalled stream or a pending animation load — gets a longer, but still
/// bounded, grace: an asset that never arrives must not leave the user on an infinite spinner.
@MainActor
final class SlideStallGuard {
    /// What the slide looked like at the end of a window.
    enum Probe {
        case finished
        /// Paused or off screen: the window doesn't count against the slide.
        case idle
        case buffering
        case progressing(watchedMs: Int)
    }

    private let timeout: TimeInterval
    private let maxBufferingWindows: Int
    private var task: Task<Void, Never>?

    init(timeout: TimeInterval, maxBufferingWindows: Int) {
        self.timeout = timeout
        self.maxBufferingWindows = maxBufferingWindows
    }

    deinit {
        task?.cancel()
    }

    func arm(probe: @escaping @MainActor () -> Probe, onStall: @escaping @MainActor () -> Void) {
        cancel()

        task = Task { [timeout, maxBufferingWindows] in
            // `nil` marks a paused window: skip one comparison after resume.
            var lastWatchedMs: Int? = 0
            var bufferingWindows = 0

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                guard !Task.isCancelled else { return }

                switch probe() {
                case .finished:
                    return
                case .idle:
                    lastWatchedMs = nil
                    bufferingWindows = 0
                case .buffering:
                    bufferingWindows += 1
                    guard bufferingWindows < maxBufferingWindows else {
                        onStall()
                        return
                    }
                    lastWatchedMs = nil
                case .progressing(let watchedMs):
                    bufferingWindows = 0
                    if let lastWatchedMs, lastWatchedMs == watchedMs {
                        onStall()
                        return
                    }
                    lastWatchedMs = watchedMs
                }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
