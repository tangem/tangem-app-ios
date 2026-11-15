//
//  TangemPayOnboardingPollingService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class TangemPayOnboardingPollingService {
    private var task: Task<Void, Never>?

    var isRunning: Bool {
        task != nil
    }

    deinit {
        cancel()
    }

    func start(refresh: @escaping () async -> Bool) {
        guard !isRunning else {
            return
        }

        task = Task { [weak self] in
            var elapsed: TimeInterval = .zero

            while let interval = Schedule.nextInterval(afterElapsed: elapsed) {
                try? await Task.sleep(for: .seconds(interval))

                guard !Task.isCancelled else {
                    return
                }

                elapsed += interval

                if await refresh() {
                    break
                }
            }

            self?.task = nil
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

extension TangemPayOnboardingPollingService {
    enum Schedule {
        static let fastInterval: TimeInterval = 10
        static let slowInterval: TimeInterval = 60
        static let fastPhaseDuration: TimeInterval = 120
        static let totalDuration: TimeInterval = 15 * 60

        static func nextInterval(afterElapsed elapsed: TimeInterval) -> TimeInterval? {
            let nextInterval = elapsed < fastPhaseDuration ? fastInterval : slowInterval

            guard elapsed + nextInterval <= totalDuration else {
                return nil
            }

            return nextInterval
        }
    }
}
