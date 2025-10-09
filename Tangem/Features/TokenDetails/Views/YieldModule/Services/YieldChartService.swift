//
//  YieldChartService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class YieldChartService {
    // MARK: - Public Implementation

    func getChartData() async throws -> YieldChartData {
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        let buckets = getBuckets()
        let averageApy = buckets.reduce(0, +) / Double(buckets.count)
        let maxApy = buckets.max() ?? 1
        let xLabels = makeMonthLabels(
            from: "2023-07-15T15:00:00.000Z",
            to: "2024-07-15T15:00:00.000Z",
            bucketsCount: buckets.count
        )

        return YieldChartData(buckets: buckets, averageApy: averageApy, maxApy: maxApy, xLabels: xLabels)
    }

    // MARK: Private Implementation

    private func getBuckets() -> [Double] {
        [
            1.8, 2.0, 2.3, 2.5, 3.0, 3.2,
            1.8, 2.0, 2.3, 2.5, 3.0, 3.2,
            6.0, 6.8, 7.5, 8.2, 6.7, 6.5,
            7.2, 8.8, 6.4, 5.0, 3.5, 4.2,
            6.9, 7.6, 8.3, 9, 9.5, 12,
        ]
    }

    private func parseISO(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }

    private func makeMonthLabels(from fromDate: String, to toDate: String, bucketsCount: Int, locale: Locale = .current) -> [String] {
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
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("LLL")

        return (0 ... 4).map { i in
            let t = from.addingTimeInterval(Double(i) * step)
            let title = formatter.string(from: t)
            return title
        }
    }
}
