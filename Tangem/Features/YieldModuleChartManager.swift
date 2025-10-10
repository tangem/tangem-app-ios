//
//  YieldModuleChartManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol YieldModuleChartManager {
    func fetchChartData(tokenContractAddress: String, chainId: Int) async throws -> YieldChartData
}

final class CommonYieldModuleChartManager {
    private let yieldModuleAPIService: YieldModuleAPIService

    init(yieldModuleAPIService: YieldModuleAPIService) {
        self.yieldModuleAPIService = yieldModuleAPIService
    }

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

// MARK: - YieldModuleChartManager

extension CommonYieldModuleChartManager: YieldModuleChartManager {
    func fetchChartData(tokenContractAddress: String, chainId: Int) async throws -> YieldChartData {
        let chartData = try await yieldModuleAPIService.getChart(
            tokenContractAddress: tokenContractAddress,
            chainId: chainId,
            window: .lastYear,
            bucketSizeDays: nil
        )

        return YieldChartData(
            buckets: chartData.data.map { $0.avgApy.doubleValue },
            averageApy: chartData.avr,
            maxApy: chartData.data.map { $0.avgApy.doubleValue }.max() ?? 0,
            xLabels: makeMonthLabels(from: chartData.from, to: chartData.to, bucketsCount: chartData.data.count)
        )
    }
}
