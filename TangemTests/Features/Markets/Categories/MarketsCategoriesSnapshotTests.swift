//
//  MarketsCategoriesSnapshotTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("MarketsCategoriesSnapshot", .tags(.marketsCategories))
struct MarketsCategoriesSnapshotTests {
    private let featured = MarketsCategoriesFixture.category(
        id: 8,
        code: MarketsCategoryCode.featuredAssets,
        displayOrder: 6,
        visible: false
    )

    @Test("Keeps the featured category out of the selectable ones")
    func featuredIsNotSelectable() {
        let snapshot = MarketsCategoriesSnapshot(
            categories: [MarketsCategoriesFixture.umbrella, featured, MarketsCategoriesFixture.commodities],
            country: "DE"
        )

        #expect(snapshot.selectableCategories.map(\.code) == [
            MarketsCategoryCode.realWorldAssets,
            MarketsCategoryCode.commodities,
        ])
    }

    @Test("Resolves the featured category by code")
    func resolvesFeatured() {
        let snapshot = MarketsCategoriesSnapshot(
            categories: [MarketsCategoriesFixture.umbrella, featured],
            country: "DE"
        )

        #expect(snapshot.featuredCategory?.id == featured.id)
    }

    @Test("Has no featured category when the backend does not send one")
    func missingFeatured() {
        let snapshot = MarketsCategoriesSnapshot(
            categories: [MarketsCategoriesFixture.umbrella, MarketsCategoriesFixture.commodities],
            country: "DE"
        )

        #expect(snapshot.featuredCategory == nil)
        #expect(snapshot.selectableCategories.count == snapshot.categories.count)
    }

    @Test("Leaves out the categories hidden in the admin")
    func hiddenCategoryIsNotSelectable() {
        let hiddenXStocks = MarketsCategoriesFixture.category(id: 2, code: MarketsCategoryCode.xstocks, displayOrder: 1, visible: false)
        let snapshot = MarketsCategoriesSnapshot(
            categories: [MarketsCategoriesFixture.umbrella, hiddenXStocks, MarketsCategoriesFixture.commodities],
            country: "DE"
        )

        #expect(snapshot.selectableCategories.map(\.code) == [
            MarketsCategoryCode.realWorldAssets,
            MarketsCategoryCode.commodities,
        ])
    }

    @Test("Shows a category whose visibility the backend does not send")
    func missingVisibilityMeansVisible() {
        let xstocks = MarketsCategoriesFixture.category(id: 2, code: MarketsCategoryCode.xstocks, displayOrder: 1, visible: nil)
        let snapshot = MarketsCategoriesSnapshot(categories: [xstocks], country: "DE")

        #expect(snapshot.selectableCategories.map(\.code) == [MarketsCategoryCode.xstocks])
    }

    @Test("Keeps the umbrella, which the admin hides by design, as the All category")
    func hiddenUmbrella() {
        let hiddenUmbrella = MarketsCategoriesFixture.category(
            id: 3,
            code: MarketsCategoryCode.realWorldAssets,
            visible: false
        )
        let snapshot = MarketsCategoriesSnapshot(
            categories: [hiddenUmbrella, MarketsCategoriesFixture.commodities],
            country: "DE"
        )

        #expect(snapshot.umbrellaCategory?.id == hiddenUmbrella.id)
        #expect(snapshot.selectableCategories.map(\.code) == [
            MarketsCategoryCode.realWorldAssets,
            MarketsCategoryCode.commodities,
        ])
    }
}
