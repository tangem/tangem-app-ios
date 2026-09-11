//
//  MarketsDefaultCategoryResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("MarketsDefaultCategoryResolver", .tags(.marketsCategories))
struct MarketsDefaultCategoryResolverTests {
    private let categories = [
        MarketsCategoriesFixture.umbrella,
        MarketsCategoriesFixture.xstocks,
        MarketsCategoriesFixture.commodities,
    ]

    @Test("Opens on commodities in the restricted regions", arguments: ["US", "GB", "us", "gb"])
    func commoditiesRegions(regionCode: String) {
        let resolved = MarketsDefaultCategoryResolver.resolve(from: categories, regionCode: regionCode)

        #expect(resolved?.code == MarketsCategoryCode.commodities)
    }

    @Test("Opens on the umbrella everywhere else", arguments: ["DE", "AE", "RU"])
    func otherRegions(regionCode: String) {
        let resolved = MarketsDefaultCategoryResolver.resolve(from: categories, regionCode: regionCode)

        #expect(resolved?.code == MarketsCategoryCode.realWorldAssets)
    }

    @Test("Opens on the umbrella when geo is unknown")
    func unknownRegion() {
        let resolved = MarketsDefaultCategoryResolver.resolve(from: categories, regionCode: nil)

        #expect(resolved?.code == MarketsCategoryCode.realWorldAssets)
    }

    @Test("Falls back to the umbrella when commodities is missing")
    func fallsBackToUmbrella() {
        let withoutCommodities = [MarketsCategoriesFixture.umbrella, MarketsCategoriesFixture.xstocks]

        let resolved = MarketsDefaultCategoryResolver.resolve(from: withoutCommodities, regionCode: "US")

        #expect(resolved?.code == MarketsCategoryCode.realWorldAssets)
    }

    @Test("Falls back to the first category when neither well-known code is present")
    func fallsBackToFirstByOrder() {
        let unknown = [
            MarketsCategoriesFixture.category(id: 7, code: "bonds", displayOrder: 4),
            MarketsCategoriesFixture.category(id: 6, code: "etfs", displayOrder: 2),
        ]

        let resolved = MarketsDefaultCategoryResolver.resolve(from: unknown, regionCode: "US")

        #expect(resolved?.code == "etfs")
    }

    @Test("Returns nothing for an empty list")
    func emptyList() {
        #expect(MarketsDefaultCategoryResolver.resolve(from: [], regionCode: "US") == nil)
    }
}
