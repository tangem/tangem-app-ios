//
//  AutoupdatingTimer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private let AutoupdateTimerLogger = AppLogger.tag("AutoupdateTimer")

final class AutoupdatingTimer {
    private var refreshDataTask: Task<Void, Error>?
    private var refreshAction: (() -> Void)?
    private var isPaused: Bool = true

    deinit {
        AutoupdateTimerLogger.debug("AutoupdatingTimer deinit")
        stopTimer()
    }

    func setup(refresh: (() -> Void)?) {
        refreshAction = refresh

        switch refreshAction {
        case .none: stopTimer()
        case .some where !isPaused: startTimer()
        // Wait until it resumed
        case .some: break
        }
    }

    func pauseTimer() {
        guard !isPaused else {
            return
        }

        isPaused = true
        stopTimer()
    }

    func resumeTimer() {
        guard isPaused else { return }
        isPaused = false

        let hasAction = refreshAction != nil
        guard hasAction else { return }

        startTimer()
    }

    private func startTimer() {
        let hasAction = refreshAction != nil
        AutoupdateTimerLogger.info("Start timer isPaused: \(isPaused) hasAction: \(hasAction)")

        refreshDataTask?.cancel()
        refreshDataTask = Task { [weak self] in
            try await Task.sleep(for: .seconds(10))
            try Task.checkCancellation()

            AutoupdateTimerLogger.info("Timer call refresh action")
            self?.refreshAction?()
        }
    }

    private func stopTimer() {
        guard refreshDataTask != nil else { return }

        let hasAction = refreshAction != nil
        AutoupdateTimerLogger.info("Stop timer isPaused: \(isPaused) hasAction: \(hasAction)")

        refreshDataTask?.cancel()
        refreshDataTask = nil
    }
}
