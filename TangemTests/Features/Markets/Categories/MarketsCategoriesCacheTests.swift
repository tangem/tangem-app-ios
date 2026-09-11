//
//  MarketsCategoriesCacheTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketsCategoriesCache", .tags(.marketsCategories))
struct MarketsCategoriesCacheTests {
    private let stored = [MarketsCategoriesFixture.umbrella, MarketsCategoriesFixture.commodities]

    @Test("Reads back what was stored for the same country")
    func readsBackForSameCountry() {
        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        let now = Date()

        cache.store(categories: stored, country: "US", at: now)

        #expect(cache.categories(for: "US", at: now) == stored)
    }

    @Test("Ignores an entry saved for a different country")
    func ignoresOtherCountry() {
        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        let now = Date()

        cache.store(categories: stored, country: "US", at: now)

        #expect(cache.categories(for: "DE", at: now) == nil)
    }

    @Test("Ignores an entry saved against another API environment")
    func ignoresOtherAPIEnvironment() {
        let storage = InMemoryPersistentStorage()
        let now = Date()

        let devCache = MarketsCategoriesCache(storage: storage, apiType: { .dev })
        devCache.store(categories: stored, country: "US", at: now)

        let stageCache = MarketsCategoriesCache(storage: storage, apiType: { .stage })

        #expect(stageCache.categories(for: "US", at: now) == nil)
        #expect(devCache.categories(for: "US", at: now) == stored)
    }

    @Test("Serves an entry younger than the TTL and drops it afterwards")
    func honoursTimeToLive() {
        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), timeToLive: 60, apiType: { .dev })
        let savedAt = Date()

        cache.store(categories: stored, country: "US", at: savedAt)

        #expect(cache.categories(for: "US", at: savedAt.addingTimeInterval(59)) == stored)
        #expect(cache.categories(for: "US", at: savedAt.addingTimeInterval(60)) == nil)
        #expect(cache.categories(for: "US", at: savedAt.addingTimeInterval(600)) == nil)
    }

    @Test("Treats a backwards clock as expired rather than valid forever")
    func rejectsNegativeAge() {
        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), timeToLive: 60, apiType: { .dev })
        let savedAt = Date()

        cache.store(categories: stored, country: "US", at: savedAt)

        #expect(cache.categories(for: "US", at: savedAt.addingTimeInterval(-1)) == nil)
    }

    @Test("Returns nothing when there is no entry at all")
    func emptyStorage() {
        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })

        #expect(cache.categories(for: "US") == nil)
    }

    @Test("Clear removes the entry")
    func clearRemovesEntry() {
        let cache = MarketsCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        let now = Date()

        cache.store(categories: stored, country: "US", at: now)
        cache.clear()

        #expect(cache.categories(for: "US", at: now) == nil)
    }

    @Test("A failing write is swallowed and leaves nothing behind")
    func swallowsWriteFailure() {
        let storage = InMemoryPersistentStorage()
        storage.storeError = MarketsCategoriesTestError.disk
        let cache = MarketsCategoriesCache(storage: storage, apiType: { .dev })

        cache.store(categories: stored, country: "US")

        #expect(cache.categories(for: "US") == nil)
    }
}
