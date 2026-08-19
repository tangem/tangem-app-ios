//
//  TokenSummaryIndicatorsTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
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
            indicator(.rsi, .positive),
            indicator(.macd, .negative),
        ]

        let result = mapper.map(readings: readings, timeframe: .day)

        #expect(result.score == TokenSummaryScore(value: 0, count: 3))
        #expect(result.score?.outlook == .neutral)
    }

    @Test("Only readings for the selected period show")
    func timeframeFiltering() {
        let readings = [
            indicator(.galaxyScore, .positive),
            indicator(.rsi, .positive),
            indicator(.macd, .positive, timeframe: .week),
        ]

        let result = mapper.map(readings: readings, timeframe: .day)

        #expect(result.metrics.count == 2)
        #expect(result.score == TokenSummaryScore(value: 2, count: 2))
    }

    @Test("Only the first reading of a repeated kind is kept")
    func dedupPerKind() {
        let readings = [
            indicator(.rsi, .positive),
            indicator(.rsi, .negative),
        ]

        let result = mapper.map(readings: readings, timeframe: .day)

        #expect(result.metrics.count == 1)
    }

    @Test("Unknown indicator kinds are dropped entirely")
    func unknownDropped() {
        let result = mapper.map(readings: [indicator(.unknown, .positive)], timeframe: .day)

        #expect(result.metrics.isEmpty)
        #expect(result.score == nil)
    }

    @Test("All-unavailable readings still produce rows but no score")
    func allUnavailableHasNoScore() {
        let readings = [
            indicator(.galaxyScore, .unavailable, value: nil),
            indicator(.rsi, .unavailable, value: nil),
        ]

        let result = mapper.map(readings: readings, timeframe: .day)

        #expect(!result.metrics.isEmpty)
        #expect(result.score == nil)
    }

    @Test("Row titles come from the contract, explanations from the client")
    func titlesComeFromBackend() throws {
        let readings = mapper.mapToDomain([
            .init(type: .rsi, name: "RSI", timeframe: .day, value: 31.68, label: .neutral, updatedAt: nil),
        ])

        let metric = try #require(mapper.map(readings: readings, timeframe: .day).metrics.first)

        #expect(metric.title == "RSI")
        #expect(!metric.info.isEmpty)
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
            .init(type: .rsi, name: "RSI", timeframe: .day, value: 61, label: .negative, updatedAt: nil),
            .init(type: .maCross, name: "MA Cross", timeframe: .week, value: nil, label: .insufficientData, updatedAt: nil),
            .init(type: .unknown("foo"), name: "Foo", timeframe: .unknown("bar"), value: nil, label: .unknown("baz"), updatedAt: nil),
        ]

        let domain = mapper.mapToDomain(readings)

        #expect(domain.count == 3)

        #expect(domain[0].kind == .rsi)
        #expect(domain[0].timeframe == .day)
        #expect(domain[0].signal == .negative)

        #expect(domain[1].kind == .maCross)
        #expect(domain[1].timeframe == .week)
        #expect(domain[1].signal == .unavailable)

        #expect(domain[2].kind == .unknown)
        #expect(domain[2].timeframe == .unknown)
        #expect(domain[2].signal == .unavailable)
    }

    private func indicator(
        _ kind: TokenSummaryIndicator.Kind,
        _ signal: TokenSummaryIndicator.Signal,
        timeframe: TokenSummaryIndicator.Timeframe = .day,
        value: Decimal? = 1
    ) -> TokenSummaryIndicator {
        TokenSummaryIndicator(kind: kind, timeframe: timeframe, title: "\(kind)", value: value, signal: signal, updatedAt: nil)
    }
}

// MARK: - Transport: the wire format the backend actually sends

@Suite("CoinIndicatorsDTO decoding")
struct CoinIndicatorsDTODecodingTests {
    /// Shaped after a real `/api/v1/coins/indicators` response: string values, `positive`/`negative` labels
    /// and a timeframe on every reading, including the social indicators.
    private let json = Data(
        """
        {
          "assets": [
            {
              "symbol": "BTC",
              "indicators": [
                {"type": "rsi", "name": "RSI", "timeframe": "24h", "value": "31.68", "label": "neutral", "updatedAt": "2026-07-30T07:51:28.299Z"},
                {"type": "macd", "name": "MACD", "timeframe": "7d", "value": "-8.20", "label": "negative", "updatedAt": "2026-07-30T07:51:28.299Z"},
                {"type": "sentiment", "name": "Sentiment", "timeframe": "1m", "value": "79.00", "label": "positive", "updatedAt": "2026-07-30T07:51:28.299Z"},
                {"type": "ma_cross", "name": "MA Cross", "timeframe": "24h", "value": null, "label": "not_available", "updatedAt": null}
              ]
            }
          ]
        }
        """.utf8
    )

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    @Test("Decodes string values, the full label vocabulary and per-reading timeframes")
    func decodesContractPayload() throws {
        let response = try decoder.decode(CoinIndicatorsDTO.Response.self, from: json)
        let asset = try #require(response.assets.first)

        #expect(asset.symbol == "BTC")
        #expect(asset.indicators.count == 4)

        #expect(asset.indicators[0].value == Decimal(string: "31.68"))
        #expect(asset.indicators[0].timeframe == .day)
        #expect(asset.indicators[0].label == .neutral)
        #expect(asset.indicators[0].name == "RSI")
        #expect(asset.indicators[0].updatedAt != nil)

        #expect(asset.indicators[1].value == Decimal(string: "-8.20"))
        #expect(asset.indicators[1].timeframe == .week)
        #expect(asset.indicators[1].label == .negative)

        #expect(asset.indicators[2].timeframe == .month)
        #expect(asset.indicators[2].label == .positive)

        #expect(asset.indicators[3].value == nil)
        #expect(asset.indicators[3].label == .notAvailable)
        #expect(asset.indicators[3].updatedAt == nil)
    }

    @Test("A reading of an unrecognized type or timeframe doesn't fail the whole response")
    func toleratesUnknownValues() throws {
        let json = Data(
            """
            {"assets": [{"symbol": "BTC", "indicators": [
              {"type": "brand_new", "name": "Brand New", "timeframe": "3y", "value": "1.00", "label": "sideways", "updatedAt": null}
            ]}]}
            """.utf8
        )

        let reading = try #require(decoder.decode(CoinIndicatorsDTO.Response.self, from: json).assets.first?.indicators.first)

        #expect(reading.type == .unknown("brand_new"))
        #expect(reading.timeframe == .unknown("3y"))
        #expect(reading.label == .unknown("sideways"))
    }

    @Test("Request sends the symbols and types the contract names")
    func requestParameters() {
        let parameters = CoinIndicatorsDTO.Request(symbols: ["BTC", "ETH"], types: [.rsi, .maCross]).parameters

        #expect(parameters["symbols"] as? String == "BTC,ETH")
        #expect(parameters["types"] as? String == "rsi,ma_cross")
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
            TokenSummaryIndicator(kind: .rsi, timeframe: .day, title: "RSI", value: nil, signal: .unavailable, updatedAt: nil),
        ]

        #expect(mapper.sentiment(for: readings, timeframe: .day) == nil)
    }

    @Test("Badge sentiment matches the Token Summary outlook for the same readings")
    func agreesWithMapperOutlook() {
        let readings = [
            TokenSummaryIndicator(kind: .rsi, timeframe: .day, title: "RSI", value: 1, signal: .positive, updatedAt: nil),
            TokenSummaryIndicator(kind: .macd, timeframe: .day, title: "MACD", value: 1, signal: .positive, updatedAt: nil),
        ]

        let outlook = TokenSummaryIndicatorsMapper().map(readings: readings, timeframe: .day).score?.outlook
        #expect(outlook == .positive)

        let sentiment = mapper.sentiment(for: readings, timeframe: .day)
        #expect(sentiment == outlook.map(ForYouTokenRowData.Sentiment.init))
    }
}
