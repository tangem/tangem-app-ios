//
//  YieldModuleChartManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol YieldModuleChartManager {
    func makeMonthTicks(bucketStarts: [Date]) -> [Int: String]
}

final class CommonYieldModuleChartManager {
    private let calendar: Calendar
    private let monthFormatter: DateFormatter

    init(locale: Locale = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        self.calendar = calendar

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = .gmt
        formatter.setLocalizedDateFormatFromTemplate("LLL")
        monthFormatter = formatter
    }
}

// MARK: - YieldModuleChartManager

extension CommonYieldModuleChartManager: YieldModuleChartManager {
    func makeMonthTicks(bucketStarts: [Date]) -> [Int: String] {
        guard bucketStarts.count > 1 else { return [:] }

        let minSpacing = Int((Double(bucketStarts.count) / Double(Constants.maxTicksCount)).rounded(.up))

        var ticks: [Int: String] = [:]
        var lastTickIndex: Int?

        for index in monthStartIndices(of: bucketStarts).reversed() {
            if let lastTickIndex, lastTickIndex - index < minSpacing {
                continue
            }

            ticks[index] = monthFormatter.string(from: bucketStarts[index])
            lastTickIndex = index
        }

        return ticks
    }

    private func monthStartIndices(of dates: [Date]) -> [Int] {
        var indices: [Int] = []
        var lastMonth: DateComponents?

        for (index, date) in dates.enumerated() {
            let month = calendar.dateComponents([.year, .month], from: date)

            if month != lastMonth {
                indices.append(index)
                lastMonth = month
            }
        }

        return indices
    }
}

// MARK: - Constants

private extension CommonYieldModuleChartManager {
    enum Constants {
        static let maxTicksCount = 5
    }
}
