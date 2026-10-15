//
//  GlowAnimationClock.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

@MainActor
final class GlowAnimationClock {
    static let shared = GlowAnimationClock()

    private var backgroundStartedAt: Date?
    private var accumulatedBackgroundTime: TimeInterval = 0

    private init() {
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
                self?.didEnterBackground(at: Date())
            }
        }

        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                self?.willEnterForeground(at: Date())
            }
        }
    }

    func time(at date: Date) -> TimeInterval {
        let ongoingBackgroundTime = backgroundStartedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0
        return date.timeIntervalSinceReferenceDate - accumulatedBackgroundTime - ongoingBackgroundTime
    }

    private func didEnterBackground(at date: Date) {
        guard backgroundStartedAt == nil else { return }
        backgroundStartedAt = date
    }

    private func willEnterForeground(at date: Date) {
        guard let startedAt = backgroundStartedAt else { return }
        accumulatedBackgroundTime += max(0, date.timeIntervalSince(startedAt))
        backgroundStartedAt = nil
    }
}
