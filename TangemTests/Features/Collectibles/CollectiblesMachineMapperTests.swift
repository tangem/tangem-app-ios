//
//  CollectiblesMachineMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CollectiblesMachineViewModel.Mapper", .serialized)
@MainActor
struct CollectiblesMachineMapperTests {
    typealias SUT = CollectiblesMachineViewModel.Mapper

    @Test(
        "A tier's detail line carries the stats it has and nothing else",
        arguments: [(true, true), (true, false), (false, true), (false, false)]
    )
    func composesTierDetail(hasRange: Bool, hasOdds: Bool) throws {
        let stats = CollectiblesMachine.TierStats(
            tier: .common,
            odds: hasOdds ? Self.odds : nil,
            valueRange: hasRange ? Self.range : nil
        )

        let details = SUT.map(Self.machine(tiers: [stats, Self.topTier]))

        let chip = try #require(details.tiers.first)

        #expect(chip.detailText == Self.expectedDetailText(hasRange: hasRange, hasOdds: hasOdds))
    }

    @Test("The top tier renders open-ended, its upper bound being a backend sentinel")
    func topTierIsOpenEnded() throws {
        let details = SUT.map(Self.machine(tiers: [Self.topTier]))

        let chip = try #require(details.tiers.last)

        #expect(chip.detailText == "\(Self.dollarText(250))+")
    }

    @Test("Pluralizes the cards count", arguments: [(1, "1 card"), (3, "3 cards")])
    func pluralizesCardsCount(count: Int, expected: String) {
        let details = SUT.map(Self.machine(cardsPerPack: count))

        #expect(details.cardsCountText == expected)
    }

    @Test("Buyback reads as a whole-percent share of the value")
    func formatsBuyback() {
        let details = SUT.map(Self.machine())

        #expect(details.buybackText == "\(Self.percentText(Self.buybackRate)) of value")
    }

    @Test("The average card value keeps its cents, unlike the tier bounds")
    func expectedValueKeepsItsCents() {
        let value = Decimal(string: "54.5")!

        let details = SUT.map(Self.machine(expectedValue: value))

        #expect(details.expectedValueText == Self.dollarText(value, fractionDigits: 2 ... 2))
    }
}

// MARK: - Helpers

private extension CollectiblesMachineMapperTests {
    static let buybackRate = Decimal(string: "0.85")!
    static let odds = Decimal(string: "0.8")!
    static let range: ClosedRange<Decimal> = 15 ... 40
    static let topTier = CollectiblesMachine.TierStats(tier: .epic, odds: nil, valueRange: 250 ... 5001)

    static func expectedDetailText(hasRange: Bool, hasOdds: Bool) -> String? {
        let rangeText = "\(dollarText(range.lowerBound))-\(dollarText(range.upperBound))"
        let oddsText = percentText(odds)

        switch (hasRange, hasOdds) {
        case (true, true): return "\(rangeText) · \(oddsText)"
        case (true, false): return rangeText
        case (false, true): return oddsText
        case (false, false): return nil
        }
    }

    /// Spells the expected money format out instead of reusing the app preset, so a change to the preset fails here.
    static func dollarText(_ value: Decimal, fractionDigits: ClosedRange<Int> = 0 ... 2) -> String {
        let options = BalanceFormattingOptions(
            minFractionDigits: fractionDigits.lowerBound,
            maxFractionDigits: fractionDigits.upperBound,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 2)
        )

        let formatter = BalanceFormatter().makeDefaultFiatFormatter(
            forCurrencyCode: AppConstants.usdCurrencyCode,
            locale: Locale(identifier: "en_US"),
            formattingOptions: options
        )

        return BalanceFormatter().formatFiatBalance(
            value,
            currencyCode: AppConstants.usdCurrencyCode,
            formattingOptions: options,
            formatter: formatter
        )
    }

    static func percentText(_ value: Decimal) -> String {
        let option = PercentFormatter.Option(fractionDigits: .init(min: 0, max: 0), prefix: .empty, suffix: .yield)

        return PercentFormatter().format(value, option: option)
    }

    static func machine(
        cardsPerPack: Int? = 1,
        expectedValue: Decimal = Decimal(string: "53.95")!,
        tiers: [CollectiblesMachine.TierStats]? = nil
    ) -> CollectiblesMachine {
        let defaultTiers = [
            CollectiblesMachine.TierStats(tier: .common, odds: odds, valueRange: range),
            topTier,
        ]

        return CollectiblesMachine(
            name: "Elite pack",
            artworkURL: nil,
            price: 50,
            cardsPerPack: cardsPerPack,
            buybackRate: buybackRate,
            expectedValue: expectedValue,
            tiers: tiers ?? defaultTiers
        )
    }
}
