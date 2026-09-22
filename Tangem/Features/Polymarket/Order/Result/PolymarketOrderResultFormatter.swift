//
//  PolymarketOrderResultFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PolymarketOrderResultFormatter {
    static func placedAt(_ date: Date) -> String {
        placedAtFormatter.string(from: date)
    }

    static func resolutionDate(_ date: Date) -> String {
        resolutionDateFormatter.string(from: date)
    }

    static func resolutionDay(_ date: Date) -> String {
        resolutionDayFormatter.string(from: date)
    }

    static func closedAt(_ date: Date) -> String {
        closedAtFormatter.string(from: date)
    }

    private static let placedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    private static let closedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let resolutionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = Constants.exchangeTimeZone
        return formatter
    }()

    private static let resolutionDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = Constants.calendarDayTimeZone
        return formatter
    }()
}

// MARK: - Constants

private extension PolymarketOrderResultFormatter {
    enum Constants {
        static let exchangeTimeZone = TimeZone(identifier: "America/New_York")
        static let calendarDayTimeZone = TimeZone(identifier: "GMT")
    }
}
