//
//  PolymarketForegroundPoller.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class PolymarketForegroundPoller {
    typealias Tick = @MainActor () async -> Void

    private let interval: TimeInterval
    private let appStateObserver: AppStateObserver

    private var loopTask: Task<Void, Never>?
    private var onTick: Tick?
    private var onPause: @MainActor () -> Void = {}
    private var isInBackground = false
    private var isSuspended = false

    init(interval: TimeInterval, notificationCenter: NotificationCenter = .default) {
        self.interval = interval
        appStateObserver = AppStateObserver(notificationCenter: notificationCenter)
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

        loopTask = Task { @MainActor [weak self] in
            if tickingNow {
                guard !Task.isCancelled, let self, isActive else { return }

                await onTick?()
            }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))

                guard !Task.isCancelled, let self, isActive else { return }

                await onTick?()
            }
        }
    }

    var isActive: Bool {
        !isInBackground && !isSuspended
    }
}
