//
//  RelativeDateFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class RelativeDateFormatter {
    static let shared = RelativeDateFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)

    private let calendar: Calendar
    private let relativeFormatter: RelativeDateTimeFormatter
    private let timeFormatter: DateFormatter
    private let detailDateFormatter: DateFormatter
    private let iso8601Formatter: ISO8601DateFormatter
    private let iso8601FormatterNoFraction: ISO8601DateFormatter

    init(calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar

        let relative = RelativeDateTimeFormatter()
        relative.locale = locale
        relative.unitsStyle = .full
        relative.dateTimeStyle = .named
        relativeFormatter = relative

        let time = DateFormatter()
        time.locale = locale
        time.dateFormat = "HH:mm"
        timeFormatter = time

        let detail = DateFormatter()
        detail.locale = locale
        detail.setLocalizedDateFormatFromTemplate("d MMMM")
        detailDateFormatter = detail

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        iso8601Formatter = iso

        let isoNoFrac = ISO8601DateFormatter()
        isoNoFrac.formatOptions = [.withInternetDateTime]
        iso8601FormatterNoFraction = isoNoFrac
    }

    /// Parses an ISO8601 date string into a Date object.
    ///
    /// Uses two formatters to handle API response variations:
    /// - First tries `iso8601Formatter` which expects fractional seconds (e.g., "2024-12-21T10:30:45.123Z")
    /// - Falls back to `iso8601FormatterNoFraction` for dates without fractional seconds (e.g., "2024-12-21T10:30:45Z")
    ///
    /// This dual-formatter approach ensures compatibility with different API response formats.
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
        formatTimeAgo(from: date, relativeTo: now)
    }

    /// Formats date using system RelativeDateTimeFormatter for proper localization:
    /// - < 12h and today: relative format ("5 minutes ago", "2 hours ago")
    /// - >= 12h and today: "Today, HH:mm"
    /// - >= 24h: Full date format ("17 January, 14:44")
    func formatTimeAgo(from date: Date, relativeTo now: Date = Date()) -> String {
        let isToday = calendar.isDateInToday(date)
        let diffInHours = now.timeIntervalSince(date) / 3600

        if diffInHours < 12, isToday {
            return relativeFormatter.localizedString(for: date, relativeTo: now)
        }

        if isToday {
            let timeString = timeFormatter.string(from: date)
            return "\(Localization.commonToday), \(timeString)"
        }

        let dateString = detailDateFormatter.string(from: date)
        let timeString = timeFormatter.string(from: date)
        return "\(dateString), \(timeString)"
    }
}
