//
//  JointAccountInviteExpiryFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

struct JointAccountInviteExpiryFormatter {
    private let calendar: Calendar
    private let locale: Locale
    private let dateProvider: DateProvider

    init(calendar: Calendar = .current, locale: Locale = .current, dateProvider: DateProvider = SystemDateProvider()) {
        self.calendar = calendar
        self.locale = locale
        self.dateProvider = dateProvider
    }

    func isExpired(_ expiresAt: Date) -> Bool {
        expiresAt <= dateProvider.now
    }

    func untilText(expiresAt: Date) -> String {
        let now = dateProvider.now

        if calendar.isDate(expiresAt, inSameDayAs: now) {
            return Localization.jointAccountInviteMembersUntilToday(format(expiresAt, dateStyle: .none))
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(expiresAt, inSameDayAs: tomorrow) {
            return Localization.jointAccountInviteMembersUntilTomorrow(format(expiresAt, dateStyle: .none))
        }

        return Localization.jointAccountInviteMembersUntil(format(expiresAt, dateStyle: .medium))
    }
}

// MARK: - Private

private extension JointAccountInviteExpiryFormatter {
    func format(_ date: Date, dateStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateStyle = dateStyle
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }
}
