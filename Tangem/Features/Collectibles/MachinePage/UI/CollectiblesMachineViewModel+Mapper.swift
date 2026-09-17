//
//  CollectiblesMachineViewModel+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

extension CollectiblesMachineViewModel {
    enum Mapper {
        private static let balanceFormatter = BalanceFormatter()
        private static let percentFormatter = PercentFormatter()

        static func map(_ machine: CollectiblesMachine) -> Details {
            Details(
                tiers: makeTierChips(of: machine),
                cardsCountText: machine.cardsPerPack.map(makeCardsCountText),
                buybackText: makeBuybackText(rate: machine.buybackRate),
                expectedValueText: makeExpectedValueText(machine.expectedValue)
            )
        }
    }
}

// MARK: - Private logic

private extension CollectiblesMachineViewModel.Mapper {
    static func makeTierChips(of machine: CollectiblesMachine) -> [CollectiblesMachineViewModel.TierChip] {
        let topTier = machine.tiers.last?.tier

        return machine.tiers.map { stats in
            CollectiblesMachineViewModel.TierChip(
                tier: stats.tier,
                title: makeTierTitle(stats.tier),
                detailText: makeTierDetailText(stats, isTopTier: stats.tier == topTier)
            )
        }
    }

    static func makeTierTitle(_ tier: CollectiblesMachine.Tier) -> String {
        switch tier {
        case .common: Localization.collectiblesMachineTierCommon
        case .uncommon: Localization.collectiblesMachineTierUncommon
        case .rare: Localization.collectiblesMachineTierRare
        case .epic: Localization.collectiblesMachineTierEpic
        // [REDACTED_TODO_COMMENT]
        case .legendary: tier.rawValue.capitalized
        }
    }

    static func makeTierDetailText(_ stats: CollectiblesMachine.TierStats, isTopTier: Bool) -> String? {
        let parts = [
            stats.valueRange.map { makeRangeText($0, isOpenEnded: isTopTier) },
            stats.odds.map { percentFormatter.format($0, option: .collectibles) },
        ]

        let text = parts.compactMap { $0 }.joined(separator: Constants.detailSeparator)
        return text.isEmpty ? nil : text
    }

    /// The top tier's upper bound is a backend sentinel, not a real cap, so it renders open-ended ("$250+").
    static func makeRangeText(_ range: ClosedRange<Decimal>, isOpenEnded: Bool) -> String {
        let lowerText = makeDollarText(range.lowerBound)

        guard !isOpenEnded else {
            return "\(lowerText)+"
        }

        return "\(lowerText)-\(makeDollarText(range.upperBound))"
    }

    /// Whole dollars for prices and tier bounds, where the mockup carries no cents.
    static func makeDollarText(_ value: Decimal) -> String {
        balanceFormatter.formatFiatBalance(
            value,
            currencyCode: AppConstants.usdCurrencyCode,
            formattingOptions: .collectiblesDollars
        )
    }

    /// The average card value is money down to the cent, so it keeps the app-wide fiat format.
    static func makeExpectedValueText(_ value: Decimal) -> String {
        balanceFormatter.formatFiatBalance(value, currencyCode: AppConstants.usdCurrencyCode)
    }

    static func makeCardsCountText(_ count: Int) -> String {
        Localization.collectiblesAccountCollectionCardsCount(count)
    }

    static func makeBuybackText(rate: Decimal) -> String {
        Localization.collectiblesMachineBuybackValue(percentFormatter.format(rate, option: .collectibles))
    }

    enum Constants {
        static let detailSeparator = " · "
    }
}
