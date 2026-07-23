//
//  TokenSummaryMetricsMapper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TokenSummaryMetricsMapper {
    struct Result {
        let metrics: [TokenSummaryMetric]
        let outlook: TokenSummaryOutlook?
        let lastUpdated: Date?
    }

    func map(readings: [TokenSummaryIndicator], period: TokenSummaryPeriod) -> Result {
        let visible = keepingFirstPerType(
            readings
                .filter { isVisible($0, in: period) }
                .sorted { displayOrder(of: $0.kind) < displayOrder(of: $1.kind) }
        )

        let metrics = visible.compactMap(makeMetric)

        return Result(
            metrics: metrics,
            outlook: aggregateOutlook(of: metrics),
            lastUpdated: visible.compactMap(\.updatedAt).max()
        )
    }
}

// MARK: - Mapping

private extension TokenSummaryMetricsMapper {
    /// One row per indicator kind — a metric's id is its title, so a duplicate kind in the same period
    /// would collide in `ForEach`. Keeps the first (already ordered by display priority).
    func keepingFirstPerType(_ readings: [TokenSummaryIndicator]) -> [TokenSummaryIndicator] {
        var seen: Set<TokenSummaryIndicator.Kind> = []
        return readings.filter { seen.insert($0.kind).inserted }
    }

    /// Timeframe-agnostic indicators (`nil` timeframe) always show; timeframed ones only for the selected period.
    func isVisible(_ reading: TokenSummaryIndicator, in period: TokenSummaryPeriod) -> Bool {
        guard let timeframe = reading.timeframe else {
            return true
        }

        return timeframe == period.timeframe
    }

    /// A reading of an unknown type has no title, so it's dropped; anything else keeps its row, either as a
    /// loaded reading or — when the signal or value is missing — as an "unavailable" row.
    func makeMetric(_ reading: TokenSummaryIndicator) -> TokenSummaryMetric? {
        guard let descriptor = Descriptor(reading.kind) else {
            return nil
        }

        let content: TokenSummaryMetric.Content

        if let sentiment = outlook(for: reading.signal), let value = formattedValue(of: reading) {
            content = .reading(value: value, sentiment: sentiment)
        } else {
            content = .unavailable
        }

        return TokenSummaryMetric(title: descriptor.title, info: descriptor.info, content: content)
    }

    func outlook(for signal: TokenSummaryIndicator.Signal) -> TokenSummaryOutlook? {
        switch signal {
        case .bullish: .positive
        case .bearish: .negative
        case .neutral: .neutral
        case .unavailable: nil
        }
    }

    func formattedValue(of reading: TokenSummaryIndicator) -> String? {
        if let value = reading.value, let formatted = Self.valueFormatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return reading.subLabel
    }

    /// Positive and negative readings net out into the gauge's overall outlook; unavailable rows don't count,
    /// a tie reads neutral, and nothing to show at all reads nil.
    func aggregateOutlook(of metrics: [TokenSummaryMetric]) -> TokenSummaryOutlook? {
        guard !metrics.isEmpty else {
            return nil
        }

        let score = metrics.reduce(into: 0) { score, metric in
            guard case .reading(_, let sentiment) = metric.content else {
                return
            }

            switch sentiment {
            case .positive: score += 1
            case .negative: score -= 1
            case .neutral: break
            }
        }

        if score > 0 {
            return .positive
        }

        if score < 0 {
            return .negative
        }

        return .neutral
    }

    func displayOrder(of kind: TokenSummaryIndicator.Kind) -> Int {
        Descriptor(kind)?.order ?? .max
    }

    static let valueFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

// MARK: - Indicator descriptors

private extension TokenSummaryMetricsMapper {
    /// Client-side display metadata for a known indicator. The contract carries no titles or descriptions,
    /// so they live here; unknown/unsupported types have none and are dropped from the list.
    // [REDACTED_TODO_COMMENT]
    struct Descriptor {
        let order: Int
        let title: String
        let info: String

        init?(_ kind: TokenSummaryIndicator.Kind) {
            switch kind {
            case .galaxyScore:
                self.init(
                    order: 0,
                    title: "Galaxy Score",
                    info: "An indicator that evaluates the current state of a cryptocurrency based on its market indicators and the dynamics of social sentiment, developed by LunarCrush."
                )
            case .sentiment:
                self.init(
                    order: 1,
                    title: "Sentiment",
                    info: "A measure of the overall mood of the market toward the asset, aggregated from social media and news activity."
                )
            case .rsi:
                self.init(
                    order: 2,
                    title: "RSI",
                    info: "The Relative Strength Index measures the speed and magnitude of recent price changes to signal overbought or oversold conditions."
                )
            case .macd:
                self.init(
                    order: 3,
                    title: "MACD",
                    info: "Moving Average Convergence Divergence tracks the relationship between two moving averages to reveal shifts in momentum."
                )
            case .maCross:
                self.init(
                    order: 4,
                    title: "MA Cross",
                    info: "Highlights when short- and long-term moving averages cross, a classic signal of a potential trend reversal."
                )
            case .unknown:
                return nil
            }
        }

        private init(order: Int, title: String, info: String) {
            self.order = order
            self.title = title
            self.info = info
        }
    }
}

// MARK: - Period → timeframe

private extension TokenSummaryPeriod {
    var timeframe: TokenSummaryIndicator.Timeframe {
        switch self {
        case .day: .day
        case .week: .week
        case .month: .month
        }
    }
}
