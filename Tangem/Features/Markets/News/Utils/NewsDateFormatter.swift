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
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter
    }()

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private lazy var relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    private lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("d MMM HH:mm")
        return formatter
    }()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = locale
        return formatter
    }()

    private lazy var detailDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("d MMMM HH:mm")
        return formatter
    }()

    private lazy var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private lazy var iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init(calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar
        self.locale = locale
    }

    func parseDate(from string: String) -> Date? {
        iso8601Formatter.date(from: string) ?? iso8601FormatterNoFraction.date(from: string)
    }

    func formatRelativeTime(from dateString: String, relativeTo now: Date = Date()) -> String {
        guard let date = parseDate(from: dateString) else {
            return dateString
        }
        return formatRelativeTime(from: date, relativeTo: now)
    }

    func formatRelativeTime(from date: Date, relativeTo now: Date = Date()) -> String {
        let hoursAgo = now.timeIntervalSince(date) / 3600
        if hoursAgo < 24 {
            return relativeFormatter.localizedString(for: date, relativeTo: now)
        } else {
            return dateTimeFormatter.string(from: date)
        }
    }

    func formatDetailDate(from dateString: String, relativeTo now: Date = Date()) -> String {
        guard let date = parseDate(from: dateString) else {
            return dateString
        }
        return formatDetailDate(from: date, relativeTo: now)
    }

    func formatDetailDate(from date: Date, relativeTo now: Date = Date()) -> String {
        if calendar.isDateInToday(date) {
            return formatTodayTime(date)
        } else {
            return detailDateTimeFormatter.string(from: date)
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

    // MARK: - Private Methods

    private func formatTodayTime(_ date: Date) -> String {
        let todayString = relativeDateFormatter.string(from: date)
        let timeString = timeFormatter.string(from: date)
        return "\(todayString), \(timeString)"
    }
}
