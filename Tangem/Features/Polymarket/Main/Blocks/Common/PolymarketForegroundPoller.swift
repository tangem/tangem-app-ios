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

    init(interval: TimeInterval, notificationCenter: NotificationCenter = .default) {
        self.interval = interval
        appStateObserver = AppStateObserver(notificationCenter: notificationCenter)
    }

    deinit {
        loopTask?.cancel()
    }

    func start(onTick: @escaping Tick, onPause: @escaping @MainActor () -> Void = {}) {
        self.onTick = onTick

        appStateObserver.start { [weak self] isInBackground in
            guard let self else { return }

            if isInBackground {
                stopLoop()
                onPause()
            } else {
                startLoop(tickingNow: true)
            }
        }

        startLoop(tickingNow: false)
    }
}

// MARK: - Loop

private extension PolymarketForegroundPoller {
    func stopLoop() {
        loopTask?.cancel()
        loopTask = nil
    }

    func startLoop(tickingNow: Bool) {
        loopTask?.cancel()

        let interval = interval

        loopTask = Task { @MainActor [weak self] in
            if tickingNow {
                await self?.onTick?()
            }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))

                guard !Task.isCancelled, let self else { return }

                await onTick?()
            }
        }
    }
}
