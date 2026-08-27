//
//  CoinIndicatorsDTO.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum CoinIndicatorsDTO {
    /// The contract rejects a request carrying more symbols than this, so callers have to batch.
    static let symbolsPerRequestLimit = 20

    struct Request: Encodable {
        let symbols: [String]?
        let types: [IndicatorType]?

        init(symbols: [String]? = nil, types: [IndicatorType]? = nil) {
            self.symbols = symbols
            self.types = types
        }

        var parameters: [String: Any] {
            var params: [String: Any] = [:]

            if let symbols, !symbols.isEmpty {
                params["symbols"] = symbols.joined(separator: ",")
            }

            if let types, !types.isEmpty {
                params["types"] = types.map(\.rawValue).joined(separator: ",")
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
        /// Display name of the indicator, worded by the backend.
        let name: String
        let timeframe: Timeframe
        /// Travels as a string with two decimals (`"67.80"`). For MA Cross it's the deviation of SMA50 from SMA200, in percent.
        @FlexibleDecimal var value: Decimal?
        let label: Signal
        let updatedAt: Date?
    }

    enum IndicatorType: Codable, Equatable {
        case rsi
        case macd
        case maCross
        case galaxyScore
        case sentiment
        case unknown(String)

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw)
        }

        init(rawValue: String) {
            switch rawValue {
            case "rsi": self = .rsi
            case "macd": self = .macd
            case "ma_cross": self = .maCross
            case "galaxy_score": self = .galaxyScore
            case "sentiment": self = .sentiment
            default: self = .unknown(rawValue)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        var rawValue: String {
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

    /// Every reading is timeframed, including the social indicators — the backend repeats each type once per timeframe.
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

    /// `insufficientData` — not enough history behind the indicator (e.g. MA Cross before SMA200 exists).
    /// `notAvailable` — the backend holds no reading it's willing to report.
    enum Signal: Decodable, Equatable {
        case positive
        case negative
        case neutral
        case insufficientData
        case notAvailable
        case unknown(String)

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            switch raw {
            case "positive": self = .positive
            case "negative": self = .negative
            case "neutral": self = .neutral
            case "insufficient_data": self = .insufficientData
            case "not_available": self = .notAvailable
            default: self = .unknown(raw)
            }
        }
    }
}
