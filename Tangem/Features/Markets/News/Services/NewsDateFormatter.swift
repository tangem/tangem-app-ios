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
        formatter.unitsStyle = .abbreviated
        formatter.dateTimeStyle = .named
        return formatter
    }()

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// Uses system relative date formatting ("Today", "Сегодня", etc.)
    private lazy var relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    /// Date + time formatter using localized template
    private lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("d MMM HH:mm")
        return formatter
    }()

    /// Full date + time formatter for detail view
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

    /// Formats date string for news list (carousel) using relative time
    /// - < 60 min: system relative format ("5m ago", "5 мин. назад")
    /// - >= 1h < 12h: system relative format ("2h ago", "2 ч. назад")
    /// - >= 12h (same day): "Today, HH:mm" (system localized)
    /// - >= 24h or different day: localized date format
    func formatRelativeTime(from dateString: String, relativeTo now: Date = Date()) -> String {
        guard let date = parseDate(from: dateString) else {
            return dateString
        }
        return formatRelativeTime(from: date, relativeTo: now)
    }

    /// Formats date for news list with relative time
    func formatRelativeTime(from date: Date, relativeTo now: Date = Date()) -> String {
        let components = calendar.dateComponents([.minute, .hour], from: date, to: now)

        let minutes = components.minute ?? 0
        let hours = components.hour ?? 0
        let totalMinutes = hours * 60 + minutes

        if totalMinutes < 60 {
            // Less than 60 minutes: use system relative formatter
            return relativeFormatter.localizedString(for: date, relativeTo: now)
        } else if totalMinutes < 12 * 60 {
            // 1h to 12h: use system relative formatter
            return relativeFormatter.localizedString(for: date, relativeTo: now)
        } else if calendar.isDateInToday(date) {
            // 12h to 24h (same day): "Today, HH:mm" using system localization
            return formatTodayTime(date)
        } else {
            // More than 24h or different day: localized date format
            return dateTimeFormatter.string(from: date)
        }
    }

    /// Formats date for news detail card
    /// - Today: "Today, HH:mm" (system localized)
    /// - Not today: localized date format
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

    // MARK: - Private Methods

    private func formatTodayTime(_ date: Date) -> String {
        let todayString = relativeDateFormatter.string(from: date)
        let timeString = timeFormatter.string(from: date)
        return "\(todayString), \(timeString)"
    }
}
