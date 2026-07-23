//
//  CommonTokenSummaryIndicatorsProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonTokenSummaryIndicatorsProvider: TokenSummaryIndicatorsProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    func loadIndicators(symbol: String) async throws -> [TokenSummaryIndicator] {
        let response = try await tangemApiService.loadCoinIndicators(requestModel: .init(symbols: [symbol]))

        // Tickers aren't unique, so keep only the asset whose symbol matches the requested one.
        let readings = response.assets
            .first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }?
            .indicators ?? []

        return readings.map(TokenSummaryIndicator.init)
    }
}

// MARK: - DTO → domain

private extension TokenSummaryIndicator {
    init(_ reading: CoinIndicatorsDTO.IndicatorReading) {
        self.init(
            kind: Kind(reading.type),
            timeframe: reading.timeframe.map(Timeframe.init),
            value: reading.value,
            signal: Signal(reading.label),
            subLabel: reading.subLabel,
            updatedAt: reading.updatedAt
        )
    }
}

private extension TokenSummaryIndicator.Kind {
    init(_ type: CoinIndicatorsDTO.IndicatorType) {
        switch type {
        case .rsi: self = .rsi
        case .macd: self = .macd
        case .maCross: self = .maCross
        case .galaxyScore: self = .galaxyScore
        case .sentiment: self = .sentiment
        case .unknown: self = .unknown
        }
    }
}

private extension TokenSummaryIndicator.Timeframe {
    init(_ timeframe: CoinIndicatorsDTO.Timeframe) {
        switch timeframe {
        case .day: self = .day
        case .week: self = .week
        case .month: self = .month
        case .unknown: self = .unknown
        }
    }
}

private extension TokenSummaryIndicator.Signal {
    init(_ signal: CoinIndicatorsDTO.Signal) {
        switch signal {
        case .bullish: self = .bullish
        case .bearish: self = .bearish
        case .neutral: self = .neutral
        case .insufficientData, .notApplicable, .na, .unknown: self = .unavailable
        }
    }
}
