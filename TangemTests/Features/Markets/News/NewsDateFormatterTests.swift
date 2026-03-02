//
//  NewsDateFormatterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Testing
@testable import Tangem

@Suite(.tags(.news))
struct NewsDateFormatterTests {
    @Test("Parses ISO8601 dates", arguments: Self.isoDates())
    func parsesIso8601Dates(_ dateString: String) {
        let formatter = NewsDateFormatter(
            calendar: Self.makeCalendar(),
            locale: Locale(identifier: "en_US_POSIX")
        )

        let parsedDate = formatter.parseDate(from: dateString)

        #expect(parsedDate != nil)
    }

    @Test("formatTimeAgo returns relative string for today under 12 hours")
    func formatTimeAgoReturnsRelativeStringForTodayUnder12Hours() {
        let formatter = NewsDateFormatter(
            calendar: Self.makeCalendar(),
            locale: Locale(identifier: "en_US_POSIX")
        )

        let date = Date()
        let now = date.addingTimeInterval(2 * 3600)

        let result = formatter.formatTimeAgo(from: date, relativeTo: now)

        #expect(result.hasPrefix("Today, ") == false)
        #expect(result.contains(", ") == false)
    }

    @Test("formatTimeAgo returns Today format for today after 12 hours")
    func formatTimeAgoReturnsTodayFormatForTodayAfter12Hours() {
        let formatter = NewsDateFormatter(
            calendar: Self.makeCalendar(),
            locale: Locale(identifier: "en_US_POSIX")
        )

        let date = Date()
        let now = date.addingTimeInterval(13 * 3600)

        let result = formatter.formatTimeAgo(from: date, relativeTo: now)
        let expectedTime = Self.formatTime(date, locale: Locale(identifier: "en_US_POSIX"))

        #expect(result.contains(", "))
        #expect(result.hasSuffix(expectedTime))
        #expect(result.contains(expectedTime))
    }

    @Test("formatTimeAgo returns date and time for previous day")
    func formatTimeAgoReturnsDateAndTimeForPreviousDay() {
        let formatter = NewsDateFormatter(
            calendar: Self.makeCalendar(),
            locale: Locale(identifier: "en_US_POSIX")
        )

        let now = Date()
        let previousDay = now.addingTimeInterval(-36 * 3600)

        let result = formatter.formatTimeAgo(from: previousDay, relativeTo: now)

        #expect(result.contains(", "))
        #expect(result.hasPrefix("Today, ") == false)
    }

    @Test("formatRelativeTime returns source string when date is invalid")
    func formatRelativeTimeReturnsSourceStringWhenDateIsInvalid() {
        let formatter = NewsDateFormatter(
            calendar: Self.makeCalendar(),
            locale: Locale(identifier: "en_US_POSIX")
        )

        let invalidDate = "not-a-date"
        let result = formatter.formatRelativeTime(from: invalidDate)

        #expect(result == invalidDate)
    }

    private static func isoDates() -> [String] {
        [
            "2025-01-02T10:11:12.345Z",
            "2025-01-02T10:11:12Z",
        ]
    }

    private static func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private static func formatTime(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
