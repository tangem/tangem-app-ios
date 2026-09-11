//
//  MarketsListDataFilterProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
@testable import Tangem

@Suite("MarketsListDataFilterProvider", .tags(.marketsCategories))
struct MarketsListDataFilterProviderTests {
    @Test("Starts without a category and with the whole order list")
    func defaults() {
        let provider = MarketsListDataFilterProvider()
        let filter = provider.currentFilterValue

        #expect(filter.categoryId == nil)
        #expect(filter.sectorId == nil)
        #expect(filter.country == nil)
        #expect(provider.supportedOrderTypes == MarketsListOrderType.allCases)
    }

    @Test("The category selection travels into the filter together with the country")
    func categorySelection() {
        let provider = MarketsListDataFilterProvider(supportedOrderTypes: [.rating, .gainers, .losers])

        provider.didSelectCategory(.init(categoryId: 2, sectorId: 7, country: "US"))
        let filter = provider.currentFilterValue

        #expect(filter.categoryId == 2)
        #expect(filter.sectorId == 7)
        #expect(filter.country == "US")
        #expect(filter.order == .rating)
        #expect(provider.supportedOrderTypes == [.rating, .gainers, .losers])
    }

    @Test("Changing the category publishes a new filter and clearing it drops the ids")
    func publishesOnCategoryChange() {
        let provider = MarketsListDataFilterProvider()
        var received: [MarketsListDataProvider.Filter] = []
        let cancellable = provider.filterPublisher.sink { received.append($0) }
        defer { cancellable.cancel() }

        provider.didSelectCategory(.init(categoryId: 3, sectorId: nil, country: "DE"))
        provider.didSelectCategory(nil)

        #expect(received.map(\.categoryId) == [nil, 3, nil])
        #expect(received[1].country == "DE")
        #expect(received[2].country == nil)
    }

    @Test("A gecko category selection travels alone: no curated ids, only the slug and the country")
    func geckoCategorySelection() {
        let provider = MarketsListDataFilterProvider()

        provider.didSelectCategory(.init(geckoCategoryId: "layer-1", country: "US"))
        let filter = provider.currentFilterValue

        #expect(filter.geckoCategoryId == "layer-1")
        #expect(filter.categoryId == nil)
        #expect(filter.sectorId == nil)
        #expect(filter.country == "US")
    }

    @Test("The request sends geckoCategoryId only when it is set")
    func geckoCategoryRequestParameter() {
        let tagged = MarketsDTO.General.Request(currency: "usd", interval: .day, order: .rating, search: nil, showNetworks: nil, geckoCategoryId: "layer-1")
        let plain = MarketsDTO.General.Request(currency: "usd", interval: .day, order: .rating, search: nil, showNetworks: nil)

        #expect(tagged.parameters["geckoCategoryId"] as? String == "layer-1")
        #expect(plain.parameters["geckoCategoryId"] == nil)
    }

    @Test("Filters that differ only by category or sector are not equal")
    func filterEquality() {
        let base = MarketsListDataProvider.Filter(interval: .day, order: .rating, categoryId: 2, sectorId: nil, country: "US")

        #expect(base == MarketsListDataProvider.Filter(interval: .day, order: .rating, categoryId: 2, sectorId: nil, country: "US"))
        #expect(base != MarketsListDataProvider.Filter(interval: .day, order: .rating, categoryId: 3, sectorId: nil, country: "US"))
        #expect(base != MarketsListDataProvider.Filter(interval: .day, order: .rating, categoryId: 2, sectorId: 7, country: "US"))
        #expect(base != MarketsListDataProvider.Filter(interval: .day, order: .rating))
        #expect(
            MarketsListDataProvider.Filter(interval: .day, order: .rating, geckoCategoryId: "layer-1")
                != MarketsListDataProvider.Filter(interval: .day, order: .rating, geckoCategoryId: "meme-token")
        )
    }
}
