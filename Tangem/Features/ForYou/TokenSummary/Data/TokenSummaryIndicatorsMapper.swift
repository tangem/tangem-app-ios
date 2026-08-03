//
//  TokenSummaryIndicatorsMapper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TokenSummaryIndicatorsMapper {
    struct Result {
        let metrics: [TokenSummaryMetric]
        let score: TokenSummaryScore?
        let lastUpdated: Date?

        /// Without a score there is either nothing loaded at all or readings that don't net into a verdict.
        var gaugeState: TokenSummaryGaugeState {
            if let score {
                return .score(score)
            }

            return metrics.isEmpty ? .dataUnavailable : .outlookUnavailable
        }
    }

    func mapToDomain(_ readings: [CoinIndicatorsDTO.IndicatorReading]) -> [TokenSummaryIndicator] {
        readings.map(makeIndicator(from:))
    }

    func map(readings: [TokenSummaryIndicator], timeframe: TokenSummaryIndicator.Timeframe) -> Result {
        let visible = keepingFirstPerType(
            readings
                .filter { isVisible($0, in: timeframe) }
                .sorted { displayOrder(of: $0.kind) < displayOrder(of: $1.kind) }
        )

        let metrics = visible.compactMap(makeMetric)

        return Result(
            metrics: metrics,
            score: aggregateScore(of: metrics),
            lastUpdated: visible.compactMap(\.updatedAt).max()
        )
    }
}

// MARK: - DTO → domain

private extension TokenSummaryIndicatorsMapper {
    func makeIndicator(from reading: CoinIndicatorsDTO.IndicatorReading) -> TokenSummaryIndicator {
        TokenSummaryIndicator(
            kind: kind(from: reading.type),
            timeframe: reading.timeframe.map(timeframe(from:)),
            value: reading.value,
            signal: signal(from: reading.label),
            subLabel: reading.subLabel,
            updatedAt: reading.updatedAt
        )
    }

    func kind(from type: CoinIndicatorsDTO.IndicatorType) -> TokenSummaryIndicator.Kind {
        switch type {
        case .rsi: .rsi
        case .macd: .macd
        case .maCross: .maCross
        case .galaxyScore: .galaxyScore
        case .sentiment: .sentiment
        case .unknown: .unknown
        }
    }

    func timeframe(from timeframe: CoinIndicatorsDTO.Timeframe) -> TokenSummaryIndicator.Timeframe {
        switch timeframe {
        case .day: .day
        case .week: .week
        case .month: .month
        case .unknown: .unknown
        }
    }

    func signal(from label: CoinIndicatorsDTO.Signal) -> TokenSummaryIndicator.Signal {
        switch label {
        case .bullish: .bullish
        case .bearish: .bearish
        case .neutral: .neutral
        case .insufficientData, .notApplicable, .na, .unknown: .unavailable
        }
    }
}

// MARK: - Domain → metrics

private extension TokenSummaryIndicatorsMapper {
    /// One row per indicator kind — a metric's id is its title, so a duplicate kind in the same period
    /// would collide in `ForEach`. Keeps the first (already ordered by display priority).
    func keepingFirstPerType(_ readings: [TokenSummaryIndicator]) -> [TokenSummaryIndicator] {
        var seen: Set<TokenSummaryIndicator.Kind> = []
        return readings.filter { seen.insert($0.kind).inserted }
    }

    /// Timeframe-agnostic indicators (`nil` timeframe) always show; timeframed ones only for the selected period.
    func isVisible(_ reading: TokenSummaryIndicator, in timeframe: TokenSummaryIndicator.Timeframe) -> Bool {
        guard let readingTimeframe = reading.timeframe else {
            return true
        }

        return readingTimeframe == timeframe
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

        return TokenSummaryMetric(kind: reading.kind, title: descriptor.title, info: descriptor.info, content: content)
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

    /// Nets the loaded readings into the gauge score: +1 per positive, −1 per negative, 0 for neutral;
    /// unavailable rows don't count. `nil` when nothing is countable, which reads as "can't load".
    func aggregateScore(of metrics: [TokenSummaryMetric]) -> TokenSummaryScore? {
        let sentiments = metrics.compactMap { metric -> TokenSummaryOutlook? in
            guard case .reading(_, let sentiment) = metric.content else {
                return nil
            }

            return sentiment
        }

        guard !sentiments.isEmpty else {
            return nil
        }

        let value = sentiments.reduce(into: 0) { value, sentiment in
            switch sentiment {
            case .positive: value += 1
            case .negative: value -= 1
            case .neutral: break
            }
        }

        return TokenSummaryScore(value: value, count: sentiments.count)
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

private extension TokenSummaryIndicatorsMapper {
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
                    info: "It is an indicator that shows the overall health of a cryptocurrency by combining its price performance with how actively and positively it's being talked about on social media, developed by LunarCrush."
                )
            case .sentiment:
                self.init(
                    order: 1,
                    title: "Sentiment",
                    info: "It is an indicator that shows whether people online are talking about the asset in a mostly positive or mostly negative way, based on social media and news data collected by LunarCrush."
                )
            case .rsi:
                self.init(
                    order: 2,
                    title: "RSI",
                    info: "It is an indicator that shows whether an asset's price has risen or fallen too quickly in the recent period, helping to spot when it might be overbought or oversold."
                )
            case .macd:
                self.init(
                    order: 3,
                    title: "MACD",
                    info: "It is an indicator that compares two price averages over different periods to show whether the asset's momentum is picking up or slowing down, and in which direction the trend may be shifting."
                )
            case .maCross:
                self.init(
                    order: 4,
                    title: "MA Cross",
                    info: "It is an indicator that compares the average price of an asset over the last 50 days with its average price over the last 200 days to show whether it's in a longer-term uptrend or downtrend."
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
