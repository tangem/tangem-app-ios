//
//  CoinIndicatorsDTO.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum CoinIndicatorsDTO {
    struct Request: Encodable {
        let symbols: [String]?
        let indicators: [IndicatorType]?

        init(symbols: [String]? = nil, indicators: [IndicatorType]? = nil) {
            self.symbols = symbols
            self.indicators = indicators
        }

        var parameters: [String: Any] {
            var params: [String: Any] = [:]

            if let symbols, !symbols.isEmpty {
                params["symbols"] = symbols.joined(separator: ",")
            }

            if let indicators, !indicators.isEmpty {
                params["indicators"] = indicators.map(\.wireValue).joined(separator: ",")
            }

            return params
        }
    }

    struct Response: Decodable {
        let assets: [AssetIndicators]
    }

    struct AssetIndicators: Decodable {
        let symbol: String
        let indicators: [IndicatorReading]
    }

    struct IndicatorReading: Decodable {
        let type: IndicatorType
        let timeframe: Timeframe?
        let value: Decimal?
        let label: Signal
        let subLabel: String?
        let updatedAt: Date?
    }

    /// `maCross`, `galaxyScore` and `sentiment` are timeframe-agnostic and always report a `nil` timeframe.
    enum IndicatorType: Codable, Equatable {
        case rsi
        case macd
        case maCross
        case galaxyScore
        case sentiment
        case unknown(String)

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(wireValue: raw)
        }

        init(wireValue: String) {
            switch wireValue {
            case "rsi": self = .rsi
            case "macd": self = .macd
            case "ma_cross": self = .maCross
            case "galaxy_score": self = .galaxyScore
            case "sentiment": self = .sentiment
            default: self = .unknown(wireValue)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(wireValue)
        }

        var wireValue: String {
            switch self {
            case .rsi: "rsi"
            case .macd: "macd"
            case .maCross: "ma_cross"
            case .galaxyScore: "galaxy_score"
            case .sentiment: "sentiment"
            case .unknown(let raw): raw
            }
        }
    }

    enum Timeframe: Decodable, Equatable {
        case day
        case week
        case month
        case unknown(String)

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            switch raw {
            case "24h": self = .day
            case "7d": self = .week
            case "1m": self = .month
            default: self = .unknown(raw)
            }
        }
    }

    /// `insufficientData` — not enough history (e.g. MA cross without SMA200).
    /// `notApplicable` — indicator not meaningful for the asset (stablecoins).
    /// `na` — no fresh data (2+ consecutive sync misses).
    enum Signal: Decodable, Equatable {
        case bullish
        case bearish
        case neutral
        case insufficientData
        case notApplicable
        case na
        case unknown(String)

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            switch raw {
            case "bullish": self = .bullish
            case "bearish": self = .bearish
            case "neutral": self = .neutral
            case "insufficient_data": self = .insufficientData
            case "not_applicable": self = .notApplicable
            case "na": self = .na
            default: self = .unknown(raw)
            }
        }
    }
}
