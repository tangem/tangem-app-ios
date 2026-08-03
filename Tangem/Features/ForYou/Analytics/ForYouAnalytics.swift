//
//  ForYouAnalytics.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Parameter values shared by the For You and Token Summary loggers.
enum ForYouAnalytics {
    enum Source: String {
        case forYou = "For You"
    }

    enum Period: String {
        case day = "Day"
        case week = "Week"
        case month = "Month"

        init(_ period: TokenSummaryPeriod) {
            switch period {
            case .day: self = .day
            case .week: self = .week
            case .month: self = .month
            }
        }
    }

    enum EarnType: String {
        case staking = "Staking"
        case yield = "Yield"

        init(_ product: EarnApyInfo.Product) {
            switch product {
            case .staking: self = .staking
            case .yieldSupply: self = .yield
            }
        }
    }

    /// The indicator titles are display copy pending localization, so the analytics values are pinned to the kind.
    enum Indicator: String {
        case galaxyScore = "Galaxy Score"
        case sentiment = "Sentiment"
        case rsi = "RSI"
        case macd = "MACD"
        case maCross = "MA Cross"

        init?(_ kind: TokenSummaryIndicator.Kind) {
            switch kind {
            case .galaxyScore: self = .galaxyScore
            case .sentiment: self = .sentiment
            case .rsi: self = .rsi
            case .macd: self = .macd
            case .maCross: self = .maCross
            case .unknown: return nil
            }
        }
    }
}
