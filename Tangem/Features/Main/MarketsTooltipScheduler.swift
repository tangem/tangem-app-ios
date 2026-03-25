//
//  MarketsTooltipScheduler.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Schedules a single delayed UI action (markets tooltip). Call only from the main actor.
final class MarketsTooltipScheduler {
    private var pendingTask: Task<Void, Never>?

    func scheduleShow(delay: TimeInterval, onMakeVisible: @escaping () -> Void) {
        pendingTask?.cancel()

        if AppEnvironment.current.isUITest {
            AppSettings.shared.marketsTooltipWasShown = true
            return
        }

        pendingTask = Task { @MainActor [weak self] in
            guard let self else { return }

            try? await Task.sleep(for: .seconds(delay))

            guard !Task.isCancelled else { return }

            guard !AppSettings.shared.marketsTooltipWasShown else {
                pendingTask = nil
                return
            }

            onMakeVisible()
            pendingTask = nil
        }
    }

    func dismiss(onHide: @escaping () -> Void) {
        pendingTask?.cancel()
        pendingTask = nil
        AppSettings.shared.marketsTooltipWasShown = true
        onHide()
    }

    func hideTemporarily(isVisible: @escaping () -> Bool, onHide: @escaping () -> Void) {
        pendingTask?.cancel()
        pendingTask = nil
        guard isVisible() else { return }
        onHide()
    }
}
