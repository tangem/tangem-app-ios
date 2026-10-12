//
//  MarketsGeckoCategoriesCacheTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketsGeckoCategoriesCache", .tags(.marketsCategories))
struct MarketsGeckoCategoriesCacheTests {
    private let stored = [MarketsGeckoCategoriesFixture.smartContracts, MarketsGeckoCategoriesFixture.did]

    @Test("Reads back what was stored for the same currency, ignoring case")
    func readsBackForSameCurrency() {
        let cache = MarketsGeckoCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        let now = Date()

        cache.store(categories: stored, currency: "USD", at: now)

        #expect(cache.categories(for: "USD", at: now) == stored)
        #expect(cache.categories(for: "usd", at: now) == stored)
    }

    @Test("Ignores an entry saved for a different currency")
    func ignoresOtherCurrency() {
        let cache = MarketsGeckoCategoriesCache(storage: InMemoryPersistentStorage(), apiType: { .dev })
        let now = Date()

        cache.store(categories: stored, currency: "USD", at: now)

        #expect(cache.categories(for: "EUR", at: now) == nil)
    }

    @Test("Ignores an entry saved against another API environment")
    func ignoresOtherAPIEnvironment() {
        let storage = InMemoryPersistentStorage()
        let now = Date()

        let devCache = MarketsGeckoCategoriesCache(storage: storage, apiType: { .dev })
        devCache.store(categories: stored, currency: "USD", at: now)

        let stageCache = MarketsGeckoCategoriesCache(storage: storage, apiType: { .stage })

        #expect(stageCache.categories(for: "USD", at: now) == nil)
        #expect(devCache.categories(for: "USD", at: now) == stored)
    }

    @Test("Serves an entry younger than the TTL and drops it afterwards or when the clock moves back")
    func honoursTimeToLive() {
        let cache = MarketsGeckoCategoriesCache(storage: InMemoryPersistentStorage(), timeToLive: 60, apiType: { .dev })
        let savedAt = Date()

        cache.store(categories: stored, currency: "USD", at: savedAt)

        #expect(cache.categories(for: "USD", at: savedAt.addingTimeInterval(59)) == stored)
        #expect(cache.categories(for: "USD", at: savedAt.addingTimeInterval(60)) == nil)
        #expect(cache.categories(for: "USD", at: savedAt.addingTimeInterval(-1)) == nil)
    }

    @Test("Survives a storage write failure and clears on demand")
    func storageFailureAndClear() {
        let storage = InMemoryPersistentStorage()
        let cache = MarketsGeckoCategoriesCache(storage: storage, apiType: { .dev })
        let now = Date()

        storage.storeError = MarketsCategoriesTestError.disk
        cache.store(categories: stored, currency: "USD", at: now)
        #expect(cache.categories(for: "USD", at: now) == nil)

        storage.storeError = nil
        cache.store(categories: stored, currency: "USD", at: now)
        #expect(cache.categories(for: "USD", at: now) == stored)

        cache.clear()
        #expect(cache.categories(for: "USD", at: now) == nil)
    }
}
