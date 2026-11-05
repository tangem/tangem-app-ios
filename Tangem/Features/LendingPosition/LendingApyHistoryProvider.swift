//
//  LendingApyHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol LendingApyHistoryProvider {
    func history(for period: LendingApyHistoryPeriod) async throws -> YieldChartData
}

struct CommonLendingApyHistoryProvider: LendingApyHistoryProvider {
    let apiService: YieldModuleAPIService
    let chainId: Int
    let wrappedNative: () async throws -> String
    var chartManager: YieldModuleChartManager = CommonYieldModuleChartManager()

    func history(for period: LendingApyHistoryPeriod) async throws -> YieldChartData {
        let chart = try await apiService.getChart(
            tokenContractAddress: wrappedNative(),
            chainId: chainId,
            window: period.window,
            bucketSizeDays: period.bucketSizeDays
        )

        let sorted = chart.data.sorted { $0.start < $1.start }
        let cutoff = sorted.last.flatMap { period.cutoff(before: $0.end) }
        let buckets = sorted.filter { bucket in cutoff.map { bucket.start >= $0 } ?? true }

        guard !buckets.isEmpty else {
            return YieldChartData(buckets: [], averageApy: 0, maxApy: 0, xTicks: [:])
        }

        let apys = buckets.map(\.avgApy.doubleValue)

        return YieldChartData(
            buckets: apys,
            averageApy: cutoff == nil ? chart.avr : apys.reduce(0, +) / Double(apys.count),
            maxApy: apys.max() ?? 0,
            xTicks: chartManager.makeMonthTicks(bucketStarts: buckets.map(\.start))
        )
    }
}

enum LendingApyHistoryPeriod: String, CaseIterable, Hashable {
    case oneMonth
    case threeMonths
    case sixMonths

    var title: String {
        switch self {
        case .oneMonth: "1M"
        case .threeMonths: "3M"
        case .sixMonths: "6M"
        }
    }

    var window: YieldModuleDTO.ChartWindow {
        switch self {
        case .oneMonth: .lastMonth
        case .threeMonths, .sixMonths: .lastYear
        }
    }

    var bucketSizeDays: Int {
        switch self {
        case .oneMonth: 1
        case .threeMonths: 3
        case .sixMonths: 6
        }
    }

    func cutoff(before date: Date) -> Date? {
        switch self {
        case .oneMonth: nil
        case .threeMonths: Calendar(identifier: .gregorian).date(byAdding: .month, value: -3, to: date)
        case .sixMonths: Calendar(identifier: .gregorian).date(byAdding: .month, value: -6, to: date)
        }
    }
}
