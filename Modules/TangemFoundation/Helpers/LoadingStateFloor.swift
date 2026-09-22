//
//  LoadingStateFloor.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Loading states that flash for a fraction of a second read as a glitch, so a fast response waits out the floor.
///
/// The interval is measured and awaited on the same monotonic clock, so moving the system clock cannot stretch it.
/// Main thread only — the release runs there too.
public final class LoadingStateFloor<ClockType: Clock<Duration>> {
    private let interval: Duration
    private let skipThreshold: Duration?
    private let clock: ClockType

    private var shownAt: ClockType.Instant?
    private var task: Task<Void, Never>?

    /// - Parameter skipThreshold: when the content arrives within it, the floor is dropped instead of padded —
    ///   for loading states shown eagerly, where an immediate swap beats a deliberate half-second.
    public init(
        interval: Duration = .milliseconds(500),
        skipThreshold: Duration? = nil,
        clock: ClockType
    ) {
        self.interval = interval
        self.skipThreshold = skipThreshold
        self.clock = clock
    }

    /// Restarts the floor, dropping a pending release.
    public func start() {
        cancel()
        shownAt = clock.now
    }

    /// Starts the floor unless it is already running, so repeated loading events don't push the release away.
    public func startIfNeeded() {
        cancel()

        if shownAt == nil {
            shownAt = clock.now
        }
    }

    /// Runs `body` once the floor has been served — immediately when it already has.
    public func release(_ body: @escaping () -> Void) {
        cancel()

        guard let remaining = remainingInterval, remaining > .zero else {
            finish(body)
            return
        }

        let clock = clock

        task = Task { @MainActor [weak self] in
            try? await clock.sleep(for: remaining)

            guard !Task.isCancelled, let self else { return }

            finish(body)
        }
    }

    /// Suspends until the floor has been served — for call sites that already own the task doing the loading.
    @MainActor
    public func wait() async {
        cancel()

        guard let remaining = remainingInterval, remaining > .zero else {
            shownAt = nil
            return
        }

        try? await clock.sleep(for: remaining)

        shownAt = nil
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }

    private var remainingInterval: Duration? {
        guard let shownAt else {
            return nil
        }

        let elapsed = shownAt.duration(to: clock.now)

        if let skipThreshold, elapsed <= skipThreshold {
            return nil
        }

        return interval - elapsed
    }

    private func finish(_ body: () -> Void) {
        shownAt = nil
        body()
    }
}

public extension LoadingStateFloor where ClockType == ContinuousClock {
    convenience init(interval: Duration = .milliseconds(500), skipThreshold: Duration? = nil) {
        self.init(interval: interval, skipThreshold: skipThreshold, clock: ContinuousClock())
    }
}
