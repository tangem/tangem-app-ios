//
//  MarketsTokenDetailsMetricsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct MarketsTokenDetailsMetricsViewModel {
    let records: [MarketsTokenDetailsMetricsView.RecordInfo]

    /// Pre-computed state for the redesigned metrics view.
    /// Groups all data that the redesign needs beyond `records`.
    let redesign: RedesignState

    private let notationFormatter: DefaultAmountNotationFormatter
    private weak var infoRouter: MarketsTokenDetailsBottomSheetRouter?

    private let formattingOptions = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: 2,
        formatEpsilonAsLowestRepresentableValue: false,
        roundingType: .default(roundingMode: .plain, scale: 0)
    )

    private let metrics: MarketsTokenDetailsMetrics
    private let cryptoCurrencyCode: String

    private let cryptoFormatter: NumberFormatter

    init(
        metrics: MarketsTokenDetailsMetrics,
        notationFormatter: DefaultAmountNotationFormatter,
        cryptoCurrencyCode: String,
        infoRouter: MarketsTokenDetailsBottomSheetRouter?
    ) {
        self.metrics = metrics
        self.notationFormatter = notationFormatter
        self.cryptoCurrencyCode = cryptoCurrencyCode
        self.infoRouter = infoRouter

        let balanceFormatter = BalanceFormatter()
        cryptoFormatter = balanceFormatter.makeDefaultCryptoFormatter(forCurrencyCode: cryptoCurrencyCode, formattingOptions: formattingOptions)

        let amountNotationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)
        let fiatFormatter = balanceFormatter.makeDefaultFiatFormatter(forCurrencyCode: AppSettings.shared.selectedCurrencyCode, formattingOptions: formattingOptions)

        let emptyValue = BalanceFormatter.defaultEmptyBalanceString

        func formatFiatValue(_ value: Decimal?) -> String {
            guard let value, value > 0 else {
                return emptyValue
            }

            return balanceFormatter.formatFiatBalance(value, formattingOptions: formattingOptions)
        }

        func formatCryptoValue(_ value: Decimal?) -> String {
            balanceFormatter.formatCryptoBalance(value, currencyCode: cryptoCurrencyCode)
        }

        var rating = emptyValue
        if let marketRating = metrics.marketRating, marketRating > 0 {
            rating = balanceFormatter.formatCryptoBalance(Decimal(marketRating), currencyCode: "", formattingOptions: formattingOptions)
        }

        var maxSupplyString = emptyValue
        if let maxSupply = metrics.maxSupply {
            if maxSupply == 0 {
                maxSupplyString = AppConstants.infinitySign
            } else {
                maxSupplyString = notationFormatter.format(maxSupply, notationFormatter: amountNotationFormatter, numberFormatter: cryptoFormatter, addingSignPrefix: false)
            }
        }
        records = [
            .init(type: .marketCapitalization, recordData: notationFormatter.format(metrics.marketCap, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: false)),
            .init(type: .marketRating, recordData: rating),
            .init(type: .tradingVolume, recordData: notationFormatter.format(metrics.volume24H, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: false)),
            .init(
                type: .fullyDilutedValuation,
                recordData: notationFormatter.format(metrics.fullyDilutedValuationChange24H, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: true),
                recordSubdata: notationFormatter.format(metrics.fullyDilutedValuation, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: false)
            ),
            .init(type: .circulatingSupply, recordData: notationFormatter.format(metrics.circulatingSupply, notationFormatter: amountNotationFormatter, numberFormatter: cryptoFormatter, addingSignPrefix: false)),
            .init(type: .maxSupply, recordData: maxSupplyString),
        ]

        redesign = Self.makeRedesignState(
            metrics: metrics,
            cryptoCurrencyCode: cryptoCurrencyCode,
            notationFormatter: notationFormatter,
            amountNotationFormatter: amountNotationFormatter,
            balanceFormatter: balanceFormatter,
            formattingOptions: formattingOptions
        )
    }

    func record(for type: MarketsTokenDetailsMetricsView.RecordType) -> MarketsTokenDetailsMetricsView.RecordInfo? {
        records.first { $0.type == type }
    }

    func showInfoBottomSheet(for type: MarketsTokenDetailsInfoDescriptionProvider) {
        infoRouter?.openInfoBottomSheet(title: type.titleFull, message: type.infoDescription)
    }
}

// MARK: - RedesignState

extension MarketsTokenDetailsMetricsViewModel {
    struct RedesignState {
        let tradingVolume: TradingVolumeState
        let marketPosition: MarketPositionState
        let formattedCirculatingSupply: String
        let formattedMaxSupply: String
        let circulatingSupplyProgress: Double?
        let cryptoCurrencyCode: String
    }

    struct TradingVolumeState {
        let liquidity: Double?
        let liquidityLevel: LiquidityLevel

        enum LiquidityLevel {
            case high
            case medium
            case low
            case unknown
        }
    }

    struct MarketPositionState {
        let rankType: RankType
        let ratingText: String?
        let progress: Double?
        let ratingChange: RatingChange

        enum RankType {
            case gold
            case silver
            case bronze
            case other
        }

        enum RatingChange {
            case up(Int)
            case down(Int)
            case none
        }
    }
}

// MARK: - RedesignState Factory

private extension MarketsTokenDetailsMetricsViewModel {
    static func makeRedesignState(
        metrics: MarketsTokenDetailsMetrics,
        cryptoCurrencyCode: String,
        notationFormatter: DefaultAmountNotationFormatter,
        amountNotationFormatter: AmountNotationSuffixFormatter,
        balanceFormatter: BalanceFormatter,
        formattingOptions: BalanceFormattingOptions
    ) -> RedesignState {
        let plainCryptoFormatter = balanceFormatter.makeDefaultCryptoFormatter(forCurrencyCode: "", formattingOptions: formattingOptions)

        let formattedCirculatingSupply = notationFormatter.format(
            metrics.circulatingSupply,
            notationFormatter: amountNotationFormatter,
            numberFormatter: plainCryptoFormatter,
            addingSignPrefix: false
        )

        let formattedMaxSupply: String
        if let maxSupply = metrics.maxSupply, maxSupply > 0 {
            formattedMaxSupply = notationFormatter.format(
                maxSupply,
                notationFormatter: amountNotationFormatter,
                numberFormatter: plainCryptoFormatter,
                addingSignPrefix: false
            )
        } else {
            formattedMaxSupply = Localization.marketsTokenDetailsMetricsNoLimited
        }

        return RedesignState(
            tradingVolume: makeTradingVolumeState(metrics: metrics),
            marketPosition: makeMarketPositionState(metrics: metrics),
            formattedCirculatingSupply: formattedCirculatingSupply,
            formattedMaxSupply: formattedMaxSupply,
            circulatingSupplyProgress: calculateCirculatingSupplyProgress(metrics: metrics),
            cryptoCurrencyCode: cryptoCurrencyCode
        )
    }

    static func calculateCirculatingSupplyProgress(metrics: MarketsTokenDetailsMetrics) -> Double? {
        guard let circulating = metrics.circulatingSupply,
              let maxSupply = metrics.maxSupply,
              maxSupply > 0 else {
            return nil
        }

        let ratio = NSDecimalNumber(decimal: circulating).doubleValue / NSDecimalNumber(decimal: maxSupply).doubleValue
        return min(max(ratio, 0), 1)
    }

    static func makeTradingVolumeState(metrics: MarketsTokenDetailsMetrics) -> TradingVolumeState {
        guard let volume = metrics.volume24H,
              let marketCap = metrics.marketCap,
              marketCap > 0 else {
            return TradingVolumeState(liquidity: nil, liquidityLevel: .unknown)
        }

        let ratio = NSDecimalNumber(decimal: volume).doubleValue / NSDecimalNumber(decimal: marketCap).doubleValue
        let liquidity = min(max(ratio, 0), 1)

        let level: TradingVolumeState.LiquidityLevel
        if liquidity >= 0.5 {
            level = .high
        } else if liquidity >= 0.2 {
            level = .medium
        } else {
            level = .low
        }

        return TradingVolumeState(liquidity: liquidity, liquidityLevel: level)
    }

    static func makeMarketPositionState(metrics: MarketsTokenDetailsMetrics) -> MarketPositionState {
        guard let rating = metrics.marketRating, rating > 0 else {
            return MarketPositionState(rankType: .other, ratingText: nil, progress: nil, ratingChange: .none)
        }

        let rankType: MarketPositionState.RankType = switch rating {
        case 1: .gold
        case 2: .silver
        case 3: .bronze
        default: .other
        }

        let progress = marketRatingProgress(for: rating)
        let ratingChange = marketRatingChange(from: metrics.marketRatingChange24H)

        return MarketPositionState(
            rankType: rankType,
            ratingText: "\(rating)",
            progress: progress,
            ratingChange: ratingChange
        )
    }

    /// Calculates dot position on the progress bar using fixed ranges with linear interpolation.
    /// Lower rating = better position = closer to right (100%).
    /// See: [REDACTED_INFO]
    static func marketRatingProgress(for rating: Int) -> Double {
        let result: Double

        switch rating {
        case 1 ... 20:
            // rating 1 → 100% (rightmost), rating 20 → 75%
            result = 1.0 + Double(rating - 1) / Double(20 - 1) * (0.75 - 1.0)
        case 21 ... 100:
            // rating 21 → 75%, rating 100 → 50%
            result = 0.75 + Double(rating - 21) / Double(100 - 21) * (0.50 - 0.75)
        case 101 ... 1000:
            // rating 101 → 50%, rating 1000 → 25%
            result = 0.50 + Double(rating - 101) / Double(1000 - 101) * (0.25 - 0.50)
        case 1001 ... 10000:
            // rating 1001 → 25%, rating 10000 → 1%
            result = 0.25 + Double(rating - 1001) / Double(10000 - 1001) * (0.01 - 0.25)
        default:
            result = 0
        }

        return min(max(result, 0), 1)
    }

    static func marketRatingChange(from change: Int?) -> MarketPositionState.RatingChange {
        guard let change, change != 0 else { return .none }

        if change > 0 {
            return .up(change)
        } else {
            return .down(abs(change))
        }
    }
}
