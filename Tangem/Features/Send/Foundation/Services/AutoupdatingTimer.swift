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

    func restartTimer(refresh: @escaping () -> Void) {
        AutoupdateTimerLogger.info("Start timer")

        refreshDataTask?.cancel()
        refreshDataTask = Task {
            try await Task.sleep(for: .seconds(10))
            try Task.checkCancellation()

            AutoupdateTimerLogger.info("Timer call autoupdate")
            refresh()
        }
    }

    func stopTimer() {
        AutoupdateTimerLogger.info("Stop timer")
        refreshDataTask?.cancel()
    }
}
