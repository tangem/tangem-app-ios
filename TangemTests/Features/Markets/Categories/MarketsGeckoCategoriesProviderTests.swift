//
//  MarketsGeckoCategoriesProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("MarketsGeckoCategoriesProvider", .tags(.marketsCategories))
struct MarketsGeckoCategoriesProviderTests {
    @Test("Sends the selected currency, keeps the backend order and attaches the resolved country")
    func sendsCurrencyAndKeepsOrder() async throws {
        let requests = OSAllocatedUnfairLock(initialState: [MarketsDTO.GeckoCategories.Request]())
        let apiService = FakeTangemApiService()
        apiService.loadCoinsGeckoCategoriesHandler = { request in
            requests.withLock { $0.append(request) }
            return .init(categories: [.did, .layer1, .smartContracts])
        }

        let provider = makeProvider(apiService: apiService, regionCode: "us", currency: "EUR")
        let snapshot = try await provider.categories()

        #expect(requests.withLock { $0.map(\.currency) } == ["EUR"])
        #expect(snapshot.country == "US")
        #expect(snapshot.categories.map(\.id) == ["decentralized-identifier-did", "layer-1", "smart-contract-platform"])
    }

    @Test("Caches a successful response under the currency it was fetched for")
    func cachesPerCurrency() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsGeckoCategoriesHandler = { _ in .init(categories: [.layer1]) }

        let cache = MarketsGeckoCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        let provider = makeProvider(apiService: apiService, regionCode: "US", currency: "USD", cache: cache)
        _ = try await provider.categories()

        #expect(cache.categories(for: "USD") == [.layer1])
        #expect(cache.categories(for: "EUR") == nil)
    }

    @Test("Still returns the categories when geo is unknown")
    func worksWithoutCountry() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsGeckoCategoriesHandler = { _ in .init(categories: [.layer1]) }

        let provider = makeProvider(apiService: apiService, regionCode: nil, currency: "USD")
        let snapshot = try await provider.categories()

        #expect(snapshot.country == nil)
        #expect(snapshot.categories == [.layer1])
    }

    @Test("Falls back to the cache when the request fails")
    func fallsBackToCache() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsGeckoCategoriesHandler = { _ in throw MarketsCategoriesTestError.network }

        let cache = MarketsGeckoCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        cache.store(categories: [.bitcoinEcosystem], currency: "USD")

        let provider = makeProvider(apiService: apiService, regionCode: "US", currency: "USD", cache: cache)
        let snapshot = try await provider.categories()

        #expect(snapshot.categories == [.bitcoinEcosystem])
        #expect(snapshot.country == "US")
    }

    @Test("Rethrows when the request fails and the cache holds another currency")
    func rethrowsOnCurrencyMismatch() async {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsGeckoCategoriesHandler = { _ in throw MarketsCategoriesTestError.network }

        let cache = MarketsGeckoCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        cache.store(categories: [.bitcoinEcosystem], currency: "EUR")

        let provider = makeProvider(apiService: apiService, regionCode: "US", currency: "USD", cache: cache)

        await #expect(throws: MarketsCategoriesTestError.network) {
            _ = try await provider.categories()
        }
    }

    @Test("Rethrows when the request fails and the cached entry is stale")
    func rethrowsOnStaleCache() async {
        let apiService = FakeTangemApiService()
        apiService.loadCoinsGeckoCategoriesHandler = { _ in throw MarketsCategoriesTestError.network }

        let cache = MarketsGeckoCategoriesCache(storage: InMemoryPersistentStorage(), timeToLive: 60, apiType: { .dev })
        cache.store(categories: [.bitcoinEcosystem], currency: "USD", at: Date().addingTimeInterval(-120))

        let provider = makeProvider(apiService: apiService, regionCode: "US", currency: "USD", cache: cache)

        await #expect(throws: MarketsCategoriesTestError.network) {
            _ = try await provider.categories()
        }
    }

    // MARK: - Helpers

    private func makeProvider(
        apiService: TangemApiService,
        regionCode: String?,
        currency: String,
        cache: MarketsGeckoCategoriesCache = MarketsGeckoCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
    ) -> MarketsGeckoCategoriesProvider {
        CommonMarketsGeckoCategoriesProvider(
            apiService: apiService,
            geoEligibilityService: MarketsStubGeoEligibilityService(geoIpRegionCode: regionCode),
            cache: cache,
            currencyCode: { currency }
        )
    }
}

private extension MarketsDTO.GeckoCategories.Category {
    static let smartContracts = MarketsGeckoCategoriesFixture.smartContracts
    static let layer1 = MarketsGeckoCategoriesFixture.layer1
    static let bitcoinEcosystem = MarketsGeckoCategoriesFixture.bitcoinEcosystem
    static let did = MarketsGeckoCategoriesFixture.did
}
