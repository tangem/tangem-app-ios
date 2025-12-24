//
//  NewsDateFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class NewsDateFormatter {
    private let calendar: Calendar
    private let locale: Locale

    private lazy var relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .short
        formatter.dateTimeStyle = .named
        return formatter
    }()

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "dd MMM, HH:mm"
        return formatter
    }()

    init(calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar
        self.locale = locale
    }

    /// Formats date according to requirements using device locale:
    /// - < 60 min: "Xm ago" (abbreviated format)
    /// - >= 1h < 12h: "Xh ago"
    /// - >= 12h < 24h: "Today, HH:mm"
    /// - >= 24h: "DD MMM, HH:mm" (localized month format)
    func formatRelativeTime(from date: Date, relativeTo now: Date = Date()) -> String {
        let components = calendar.dateComponents([.minute, .hour], from: date, to: now)

        let minutes = components.minute ?? 0
        let hours = components.hour ?? 0
        let totalMinutes = hours * 60 + minutes

        if totalMinutes < 60 {
            // Less than 60 minutes: "Xm ago"
            return relativeFormatter.localizedString(for: date, relativeTo: now)
        } else if totalMinutes < 12 * 60 {
            // 1h to 12h: "Xh ago"
            return relativeFormatter.localizedString(for: date, relativeTo: now)
        } else if calendar.isDateInToday(date) {
            // 12h to 24h (same day): "Today, HH:mm"
            let time = timeFormatter.string(from: date)
            return "Today, \(time)"
        } else {
            // More than 24h: "DD MMM, HH:mm"
            return dateTimeFormatter.string(from: date)
        }
    }
}
