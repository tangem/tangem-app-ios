//
//  NewsDateFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

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

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = locale
        return formatter
    }()

    init(calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar
        self.locale = locale
    }

    /// Formats date according to requirements using device locale:
    /// - < 12h: Uses `RelativeDateTimeFormatter` which automatically formats as "Xm ago" for minutes or "Xh ago" for hours
    /// - >= 12h < 24h (same day): "Today, HH:mm"
    /// - >= 24h: "DD MMM, HH:mm" (localized month format)
    func formatRelativeTime(from date: Date, relativeTo now: Date = Date()) -> String {
        let components = calendar.dateComponents([.minute, .hour], from: date, to: now)

        let minutes = components.minute ?? 0
        let hours = components.hour ?? 0
        let totalMinutes = hours * 60 + minutes

        if totalMinutes < 12 * 60 {
            // Less than 12 hours: RelativeDateTimeFormatter automatically formats as "Xm ago" or "Xh ago"
            return relativeFormatter.localizedString(for: date, relativeTo: now)
        } else if calendar.isDateInToday(date) {
            // 12h to 24h (same day): "Today, HH:mm"
            let time = timeFormatter.string(from: date)
            return "\(Localization.commonToday), \(time)"
        } else {
            // More than 24h: "DD MMM, HH:mm"
            return dateTimeFormatter.string(from: date)
        }
    }

    /// Formats date with localized strings for minutes and hours:
    /// - < 1 min: "1 minute ago" (localized)
    /// - < 60 min: "X minutes ago" (localized)
    /// - < 12h and today: "X hours ago" (localized)
    /// - >= 12h and today: "Today, HH:mm"
    /// - >= 24h: Medium date format (localized)
    func formatTimeAgo(from date: Date, relativeTo now: Date = Date()) -> String {
        let isToday = calendar.isDateInToday(date)

        let diffInSeconds = now.timeIntervalSince(date)
        let diffInMinutes = Int(diffInSeconds / 60)
        let diffInHours = Int(diffInSeconds / 3600)

        if diffInMinutes < 1 {
            return Localization.newsPublishedMinutesAgo(1)
        }

        if diffInMinutes < 60 {
            return Localization.newsPublishedMinutesAgo(diffInMinutes)
        }

        if diffInHours < 12, isToday {
            return Localization.newsPublishedHoursAgo(diffInHours)
        }

        if isToday {
            let timeString = timeFormatter.string(from: date)
            return "\(Localization.commonToday), \(timeString)"
        }

        return dateFormatter.string(from: date)
    }
}
