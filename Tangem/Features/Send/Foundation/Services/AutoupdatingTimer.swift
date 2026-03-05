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

    func restartTimer(_ reason: String = "Start timer", refresh: @escaping () -> Void) {
        AutoupdateTimerLogger.info(reason)
        refreshAction = refresh

        refreshDataTask?.cancel()
        refreshDataTask = Task {
            try await Task.sleep(for: .seconds(10))
            try Task.checkCancellation()

            AutoupdateTimerLogger.info("Timer call autoupdate")
            refreshAction?()
        }
    }

    func pauseTimer() {
        stopTimer("Pause timer")
    }

    func resumeTimer() {
        guard let refreshAction else {
            AutoupdateTimerLogger.info("Timer wasn't resume, refreshAction is nil")
            return
        }

        restartTimer("Resume timer", refresh: refreshAction)
    }

    func stopTimer(_ reason: String = "Stop timer") {
        guard refreshDataTask != nil else {
            return
        }

        AutoupdateTimerLogger.info(reason)
        refreshDataTask?.cancel()
        refreshDataTask = nil
    }
}
