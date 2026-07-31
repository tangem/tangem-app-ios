//
//  TokenSummaryIndicatorsTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Score / outlook thresholds

@Suite("TokenSummaryScore")
struct TokenSummaryScoreTests {
    @Test("Small sets (N ≤ 3) read by the plain sign of the net signal")
    func smallSetsBySign() {
        #expect(TokenSummaryScore(value: 1, count: 1).outlook == .positive)
        #expect(TokenSummaryScore(value: -1, count: 1).outlook == .negative)
        #expect(TokenSummaryScore(value: 0, count: 3).outlook == .neutral)
        #expect(TokenSummaryScore(value: 3, count: 3).outlook == .positive)
        #expect(TokenSummaryScore(value: -2, count: 3).outlook == .negative)
    }

    @Test("Large sets (N ≥ 4) apply the ±2 neutral dead-zone")
    func largeSetsNeutralBand() {
        #expect(TokenSummaryScore(value: 2, count: 4).outlook == .neutral)
        #expect(TokenSummaryScore(value: -2, count: 4).outlook == .neutral)
        #expect(TokenSummaryScore(value: 3, count: 4).outlook == .positive)
        #expect(TokenSummaryScore(value: -3, count: 4).outlook == .negative)
        #expect(TokenSummaryScore(value: 2, count: 5).outlook == .neutral)
        #expect(TokenSummaryScore(value: 3, count: 5).outlook == .positive)
        #expect(TokenSummaryScore(value: -3, count: 5).outlook == .negative)
    }

    @Test("Thumb position and tick count follow the score geometry")
    func geometry() {
        #expect(TokenSummaryScore(value: 2, count: 4).normalizedPosition == 0.75)
        #expect(TokenSummaryScore(value: 0, count: 5).normalizedPosition == 0.5)
        #expect(TokenSummaryScore(value: -5, count: 5).normalizedPosition == 0.0)
        #expect(TokenSummaryScore(value: 5, count: 5).normalizedPosition == 1.0)
        #expect(TokenSummaryScore(value: 0, count: 5).tickCount == 11)
        #expect(TokenSummaryScore(value: 0, count: 1).tickCount == 3)
    }
}

// MARK: - Mapper: DTO → domain and readings → metrics/score

@Suite("TokenSummaryIndicatorsMapper")
struct TokenSummaryIndicatorsMapperTests {
    private let mapper = TokenSummaryIndicatorsMapper()

    @Test("Nets directional signals into the score; neutral counts as zero")
    func aggregatesScore() {
        let readings = [
            indicator(.galaxyScore, .neutral),
            indicator(.rsi, .bullish, timeframe: .day),
            indicator(.macd, .bearish, timeframe: .day),
        ]

        let result = mapper.map(readings: readings, timeframe: .day)

        #expect(result.score == TokenSummaryScore(value: 0, count: 3))
        #expect(result.score?.outlook == .neutral)
    }

    @Test("Timeframe-agnostic readings always show; timeframed ones only for the selected period")
    func timeframeFiltering() {
        let readings = [
            indicator(.galaxyScore, .bullish),
            indicator(.rsi, .bullish, timeframe: .day),
            indicator(.macd, .bullish, timeframe: .week),
        ]

        let result = mapper.map(readings: readings, timeframe: .day)

        #expect(result.metrics.count == 2)
        #expect(result.score == TokenSummaryScore(value: 2, count: 2))
    }

    @Test("Only the first reading of a repeated kind is kept")
    func dedupPerKind() {
        let readings = [
            indicator(.rsi, .bullish, timeframe: .day),
            indicator(.rsi, .bearish, timeframe: .day),
        ]

        let result = mapper.map(readings: readings, timeframe: .day)

        #expect(result.metrics.count == 1)
    }

    @Test("Unknown indicator kinds are dropped entirely")
    func unknownDropped() {
        let result = mapper.map(readings: [indicator(.unknown, .bullish, timeframe: .day)], timeframe: .day)

        #expect(result.metrics.isEmpty)
        #expect(result.score == nil)
    }

    @Test("All-unavailable readings still produce rows but no score")
    func allUnavailableHasNoScore() {
        let readings = [
            indicator(.galaxyScore, .unavailable, value: nil),
            indicator(.rsi, .unavailable, timeframe: .day, value: nil),
        ]

        let result = mapper.map(readings: readings, timeframe: .day)

        #expect(!result.metrics.isEmpty)
        #expect(result.score == nil)
    }

    @Test("Empty readings yield no metrics and no score")
    func emptyReadings() {
        let result = mapper.map(readings: [], timeframe: .day)

        #expect(result.metrics.isEmpty)
        #expect(result.score == nil)
    }

    @Test("Maps transport readings into the domain model, collapsing non-directional signals")
    func mapsDtoToDomain() {
        let readings: [CoinIndicatorsDTO.IndicatorReading] = [
            .init(type: .rsi, timeframe: .day, value: 61, label: .bearish, subLabel: "Overbought", updatedAt: nil),
            .init(type: .maCross, timeframe: nil, value: nil, label: .insufficientData, subLabel: nil, updatedAt: nil),
            .init(type: .unknown("foo"), timeframe: .unknown("bar"), value: nil, label: .unknown("baz"), subLabel: nil, updatedAt: nil),
        ]

        let domain = mapper.mapToDomain(readings)

        #expect(domain.count == 3)

        #expect(domain[0].kind == .rsi)
        #expect(domain[0].timeframe == .day)
        #expect(domain[0].signal == .bearish)

        #expect(domain[1].kind == .maCross)
        #expect(domain[1].timeframe == nil)
        #expect(domain[1].signal == .unavailable)

        #expect(domain[2].kind == .unknown)
        #expect(domain[2].timeframe == .unknown)
        #expect(domain[2].signal == .unavailable)
    }

    private func indicator(
        _ kind: TokenSummaryIndicator.Kind,
        _ signal: TokenSummaryIndicator.Signal,
        timeframe: TokenSummaryIndicator.Timeframe? = nil,
        value: Decimal? = 1
    ) -> TokenSummaryIndicator {
        TokenSummaryIndicator(kind: kind, timeframe: timeframe, value: value, signal: signal, subLabel: nil, updatedAt: nil)
    }
}

// MARK: - Portfolio Review badge agrees with the shared outlook

@Suite("PortfolioReviewSentimentMapper")
struct PortfolioReviewSentimentMapperTests {
    private let mapper = PortfolioReviewSentimentMapper()

    @Test("Nil readings produce no sentiment")
    func nilReadings() {
        #expect(mapper.sentiment(for: nil, timeframe: .day) == nil)
    }

    @Test("All-unavailable readings produce no sentiment")
    func allUnavailable() {
        let readings = [
            TokenSummaryIndicator(kind: .rsi, timeframe: .day, value: nil, signal: .unavailable, subLabel: nil, updatedAt: nil),
        ]

        #expect(mapper.sentiment(for: readings, timeframe: .day) == nil)
    }

    @Test("Badge sentiment matches the Token Summary outlook for the same readings")
    func agreesWithMapperOutlook() {
        let readings = [
            TokenSummaryIndicator(kind: .rsi, timeframe: .day, value: 1, signal: .bullish, subLabel: nil, updatedAt: nil),
            TokenSummaryIndicator(kind: .macd, timeframe: .day, value: 1, signal: .bullish, subLabel: nil, updatedAt: nil),
        ]

        let outlook = TokenSummaryIndicatorsMapper().map(readings: readings, timeframe: .day).score?.outlook
        #expect(outlook == .positive)

        let sentiment = mapper.sentiment(for: readings, timeframe: .day)
        #expect(sentiment == outlook.map(ForYouTokenRowData.Sentiment.init))
    }
}
