//
//  MarketsCategoriesProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("MarketsCategoriesProvider", .tags(.marketsCategories))
struct MarketsCategoriesProviderTests {
    @Test("Sends the resolved country and returns the categories ordered by displayOrder")
    func sendsCountryAndOrdersCategories() async throws {
        let requests = OSAllocatedUnfairLock(initialState: [MarketsDTO.Categories.Request]())
        let apiService = FakeTangemApiService()
        apiService.loadCoinsCategoriesHandler = { request in
            requests.withLock { $0.append(request) }
            // Deliberately out of order, so ordering cannot pass by accident.
            return .init(categories: [.commoditiesFixture, .xstocksFixture, .umbrellaFixture])
        }

        let provider = makeProvider(apiService: apiService, regionCode: "US")
        let snapshot = try await provider.categories()

        #expect(requests.withLock { $0.count } == 1)
        #expect(requests.withLock { $0.first?.country } == "US")
        #expect(snapshot.country == "US")
        #expect(snapshot.categories.map(\.code) == [
            MarketsCategoryCode.realWorldAssets,
            "xstocks",
            MarketsCategoryCode.commodities,
        ])
    }

    @Test("Caches a successful response fetched with a country")
    func cachesWithCountry() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsCategoriesHandler = { _ in .init(categories: [.umbrellaFixture]) }

        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        let provider = makeProvider(apiService: apiService, regionCode: "US", cache: cache)
        _ = try await provider.categories()

        #expect(cache.categories(for: "US") == [.umbrellaFixture])
    }

    @Test("Never caches a response fetched without a country")
    func doesNotCacheWithoutCountry() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsCategoriesHandler = { _ in .init(categories: [.umbrellaFixture]) }

        let storage = InMemoryPersistentStorage()
        let cache = MarketsCategoriesCache(storage: storage, apiType: { .dev })
        let provider = makeProvider(apiService: apiService, regionCode: nil, cache: cache)
        let snapshot = try await provider.categories()

        #expect(snapshot.country == nil)
        #expect(snapshot.categories == [.umbrellaFixture])

        let entry: MarketsCategoriesCache.Entry? = try storage.value(for: .coinsCategoriesCache)
        #expect(entry == nil)
    }

    @Test("Treats an empty region code as no country at all")
    func treatsEmptyCountryAsMissing() async throws {
        let requests = OSAllocatedUnfairLock(initialState: [MarketsDTO.Categories.Request]())
        let apiService = FakeTangemApiService()
        apiService.loadCoinsCategoriesHandler = { request in
            requests.withLock { $0.append(request) }
            return .init(categories: [.umbrellaFixture])
        }

        let storage = InMemoryPersistentStorage()
        let cache = MarketsCategoriesCache(storage: storage, apiType: { .dev })
        let provider = makeProvider(apiService: apiService, regionCode: "", cache: cache)
        let snapshot = try await provider.categories()

        #expect(snapshot.country == nil)
        #expect(requests.withLock { $0.first?.country } == nil)

        let entry: MarketsCategoriesCache.Entry? = try storage.value(for: .coinsCategoriesCache)
        #expect(entry == nil)
    }

    @Test("Falls back to the cache when the request fails")
    func fallsBackToCache() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsCategoriesHandler = { _ in throw MarketsCategoriesTestError.network }

        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        cache.store(categories: [.commoditiesFixture], country: "US")

        let provider = makeProvider(apiService: apiService, regionCode: "US", cache: cache)
        let snapshot = try await provider.categories()

        #expect(snapshot.categories == [.commoditiesFixture])
        #expect(snapshot.country == "US")
    }

    @Test("Rethrows when the request fails and the cache holds another country")
    func rethrowsOnCountryMismatch() async {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsCategoriesHandler = { _ in throw MarketsCategoriesTestError.network }

        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        cache.store(categories: [.commoditiesFixture], country: "DE")

        let provider = makeProvider(apiService: apiService, regionCode: "US", cache: cache)

        await #expect(throws: MarketsCategoriesTestError.network) {
            _ = try await provider.categories()
        }
    }

    @Test("Rethrows when the request fails and the cached entry is stale")
    func rethrowsOnStaleCache() async {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsCategoriesHandler = { _ in throw MarketsCategoriesTestError.network }

        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), timeToLive: 60, apiType: { .dev })
        cache.store(categories: [.commoditiesFixture], country: "US", at: Date().addingTimeInterval(-120))

        let provider = makeProvider(apiService: apiService, regionCode: "US", cache: cache)

        await #expect(throws: MarketsCategoriesTestError.network) {
            _ = try await provider.categories()
        }
    }

    @Test("Rethrows when the request fails and geo is unknown, leaving the cache untouched")
    func rethrowsWithoutCountry() async {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsCategoriesHandler = { _ in throw MarketsCategoriesTestError.network }

        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        cache.store(categories: [.commoditiesFixture], country: "US")

        let provider = makeProvider(apiService: apiService, regionCode: nil, cache: cache)

        await #expect(throws: MarketsCategoriesTestError.network) {
            _ = try await provider.categories()
        }
    }

    // MARK: - Helpers

    private func makeProvider(
        apiService: TangemApiService,
        regionCode: String?,
        cache: MarketsCategoriesCache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
    ) -> MarketsCategoriesProvider {
        CommonMarketsCategoriesProvider(
            apiService: apiService,
            geoEligibilityService: MarketsStubGeoEligibilityService(geoIpRegionCode: regionCode),
            cache: cache
        )
    }
}

private extension MarketsDTO.Categories.Category {
    static let umbrellaFixture = MarketsCategoriesFixture.umbrella
    static let commoditiesFixture = MarketsCategoriesFixture.commodities
    static let xstocksFixture = MarketsCategoriesFixture.xstocks
}
