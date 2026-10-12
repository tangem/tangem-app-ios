//
//  MarketsCategoryLocalizerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemLocalization
@testable import Tangem

@Suite("MarketsCategoryLocalizer", .tags(.marketsCategories))
struct MarketsCategoryLocalizerTests {
    @Test("The umbrella reads as All")
    func umbrella() {
        #expect(MarketsCategoryLocalizer.title(for: MarketsCategoriesFixture.umbrella) == Localization.commonAll)
    }

    @Test("Known codes are localized regardless of the server display name")
    func knownCode() {
        let category = MarketsCategoriesFixture.category(id: 5, code: MarketsCategoryCode.commodities)

        #expect(MarketsCategoryLocalizer.title(for: category) == Localization.marketsRealAssetsCategoryCommodities)
    }

    @Test("Unknown codes fall back to the server display name")
    func unknownCode() {
        let category = MarketsCategoriesFixture.category(id: 9, code: "collectibles")

        #expect(MarketsCategoryLocalizer.title(for: category) == "Collectibles")
    }

    @Test("Sector titles are scoped by category")
    func sectorScopedByCategory() {
        let sector = MarketsCategoriesFixture.sector(id: 11, code: MarketsCategoryCode.Sector.technology.rawValue)
        let xstocks = MarketsCategoriesFixture.category(id: 2, code: MarketsCategoryCode.xstocks, sectors: [sector])
        let other = MarketsCategoriesFixture.category(id: 8, code: "etfs", sectors: [sector])

        #expect(MarketsCategoryLocalizer.title(for: sector, in: xstocks) == Localization.marketsRealAssetsSectorXstocksTechnology)
        #expect(MarketsCategoryLocalizer.title(for: sector, in: other) == sector.displayName)
    }

    @Test("A selection shows the sector when one is chosen, otherwise the category")
    func selectionTitle() {
        let sector = MarketsCategoriesFixture.sector(id: 11, code: MarketsCategoryCode.Sector.energy.rawValue)
        let xstocks = MarketsCategoriesFixture.category(id: 2, code: MarketsCategoryCode.xstocks, sectors: [sector])

        #expect(RealAssetsCategorySelection(category: xstocks).title == Localization.marketsRealAssetsCategoryXstocks)
        #expect(RealAssetsCategorySelection(category: xstocks, sector: sector).title == Localization.marketsRealAssetsSectorXstocksEnergy)
    }

    @Test("Only the bare umbrella counts as the unfiltered state")
    func umbrellaSelection() {
        let sector = MarketsCategoriesFixture.sector(id: 11, code: MarketsCategoryCode.Sector.energy.rawValue)

        #expect(RealAssetsCategorySelection(category: MarketsCategoriesFixture.umbrella).isUmbrella)
        #expect(!RealAssetsCategorySelection(category: MarketsCategoriesFixture.umbrella, sector: sector).isUmbrella)
        #expect(!RealAssetsCategorySelection(category: MarketsCategoriesFixture.commodities).isUmbrella)
    }
}
