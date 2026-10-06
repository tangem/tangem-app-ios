//
//  YieldIncentiveChartMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct YieldIncentiveChartMapper {
    // Points are UTC calendar days; label in UTC too, or negative offsets shift every label a day back.
    private let weekdayFormatter = Self.makeFormatter(template: "EEEEE")
    private let monthFormatter = Self.makeFormatter(template: "LLL")

    private let utcCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = .gmt
        return calendar
    }()

    func map(points: [YieldIncentiveAprPoint], period: YieldIncentiveChartPeriod) -> YieldIncentiveChartData {
        let totals = points.map { NSDecimalNumber(decimal: $0.totalApyEst * 100).doubleValue }
        let averageApy = totals.isEmpty ? nil : totals.reduce(0, +) / Double(totals.count)

        return YieldIncentiveChartData(
            baseApyData: points.map { NSDecimalNumber(decimal: $0.baseApy * 100).doubleValue },
            totalApyData: totals,
            xTicks: makeTicks(dates: points.map(\.date), period: period),
            averageApy: averageApy
        )
    }

    private func makeTicks(dates: [Date], period: YieldIncentiveChartPeriod) -> [Int: String] {
        guard !dates.isEmpty else { return [:] }

        switch period {
        case .week:
            // One narrow weekday letter per bar.
            return Dictionary(
                uniqueKeysWithValues: dates.enumerated().map { ($0.offset, weekdayFormatter.string(from: $0.element)) }
            )

        case .threeMonths:
            // A month label on the first point of every month.
            var ticks: [Int: String] = [:]
            var lastMonth: Int?

            for (index, date) in dates.enumerated() {
                let month = utcCalendar.component(.month, from: date)
                if month != lastMonth {
                    ticks[index] = monthFormatter.string(from: date)
                    lastMonth = month
                }
            }

            return ticks
        }
    }

    private static func makeFormatter(template: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = .gmt
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }
}
