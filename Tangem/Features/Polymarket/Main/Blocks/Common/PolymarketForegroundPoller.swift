//
//  PolymarketForegroundPoller.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class PolymarketForegroundPoller {
    typealias Tick = @MainActor () async -> Void

    private let interval: TimeInterval
    private let appStateObserver: AppStateObserving
    private let delayProvider: PollDelayProvider

    private var loopTask: Task<Void, Never>?
    private var onTick: Tick?
    private var onPause: @MainActor () -> Void = {}
    private var isInBackground = false
    private var isSuspended = false

    convenience init(interval: TimeInterval, notificationCenter: NotificationCenter = .default) {
        self.init(
            interval: interval,
            appStateObserver: AppStateObserver(notificationCenter: notificationCenter),
            delayProvider: TaskSleepPollDelayProvider()
        )
    }

    init(interval: TimeInterval, appStateObserver: AppStateObserving, delayProvider: PollDelayProvider) {
        self.interval = interval
        self.appStateObserver = appStateObserver
        self.delayProvider = delayProvider
    }

    deinit {
        loopTask?.cancel()
    }

    func start(onTick: @escaping Tick, onPause: @escaping @MainActor () -> Void = {}) {
        self.onTick = onTick
        self.onPause = onPause

        appStateObserver.start { [weak self] isInBackground in
            guard let self else { return }

            self.isInBackground = isInBackground

            if isInBackground {
                pause()
            } else if !isSuspended {
                startLoop(tickingNow: true)
            }
        }

        startLoop(tickingNow: false)
    }

    @MainActor
    func setSuspended(_ isSuspended: Bool) {
        guard self.isSuspended != isSuspended else { return }

        self.isSuspended = isSuspended

        guard !isInBackground else { return }

        if isSuspended {
            pause()
        } else {
            startLoop(tickingNow: true)
        }
    }
}

// MARK: - Loop

private extension PolymarketForegroundPoller {
    @MainActor
    func pause() {
        stopLoop()
        onPause()
    }

    func stopLoop() {
        loopTask?.cancel()
        loopTask = nil
    }

    func startLoop(tickingNow: Bool) {
        loopTask?.cancel()

        let interval = interval
        let delayProvider = delayProvider

        loopTask = Task { @MainActor [weak self] in
            if tickingNow {
                guard !Task.isCancelled, let self, isActive else { return }

                await onTick?()
            }

            while !Task.isCancelled {
                try? await delayProvider.wait(for: interval)

                guard !Task.isCancelled, let self, isActive else { return }

                await onTick?()
            }
        }
    }

    var isActive: Bool {
        !isInBackground && !isSuspended
    }
}
