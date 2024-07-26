//
//  CommonMarketsHistoryChartProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Andrey Fedorov - Add actual implementation (IOS-7109)
final class CommonMarketsHistoryChartProvider {}

// MARK: - MarketsHistoryChartProvider protocol conformance

extension CommonMarketsHistoryChartProvider: MarketsHistoryChartProvider {
    func loadHistoryChart(for interval: MarketsPriceIntervalType) async throws -> MarketsChartsHistoryItemModel {
        try await Task.sleep(seconds: 2.0)

        switch interval {
        case .day:
            return .ethereumDay
        case .week:
            return .ethereumWeek
        case .month:
            return .ethereumMonth
        case .quarter:
            return .ethereumQuarter
        case .halfYear:
            return .ethereumHalfYear
        case .year:
            return .ethereumYear
        case .all:
            return .ethereumAll
        }
    }
}