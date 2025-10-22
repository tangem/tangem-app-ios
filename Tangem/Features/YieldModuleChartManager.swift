//
//  YieldModuleChartManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol YieldModuleChartManager {
    func makeMonthLabels(from fromDate: String, to toDate: String, bucketsCount: Int) -> [String]
}

final class CommonYieldModuleChartManager {
    // MARK: - Private Implementation

    private func parseISO(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withFullDate,
            .withFullTime,
            .withColonSeparatorInTime,
            .withDashSeparatorInDate,
            .withTimeZone,
        ]
        return formatter.date(from: string)
    }
}

extension CommonYieldModuleChartManager: YieldModuleChartManager {
    func makeMonthLabels(from fromDate: String, to toDate: String, bucketsCount: Int) -> [String] {
        guard
            let from = parseISO(fromDate),
            let to = parseISO(toDate),
            to > from,
            bucketsCount > 1
        else {
            return []
        }

        let total = to.timeIntervalSince(from)
        let step = total / 4.0

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("LLL")

        return (0 ... 4).map { i in
            let t = from.addingTimeInterval(Double(i) * step)
            let title = formatter.string(from: t)
            return title
        }
    }
}
