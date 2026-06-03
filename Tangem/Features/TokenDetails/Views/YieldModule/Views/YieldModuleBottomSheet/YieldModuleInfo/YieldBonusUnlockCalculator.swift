//
//  YieldBonusUnlockCalculator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum YieldBonusUnlockCalculator {
    static func daysLeft(activationDate: Date, now: Date = .now, calendar: Calendar = .current) -> Int? {
        let bonusDurationDays = 30
        guard let unlockDate = calendar.date(byAdding: .day, value: bonusDurationDays, to: activationDate) else {
            return nil
        }
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: unlockDate)
        ).day
    }
}
