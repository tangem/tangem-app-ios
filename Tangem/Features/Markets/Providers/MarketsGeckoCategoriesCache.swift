//
//  MarketsGeckoCategoriesCache.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A fallback for a failed `/v1/coins/gecko-categories`, not a read-through cache: the provider requests fresh
/// data every time and only reads the stored payload once that request fails.
final class MarketsGeckoCategoriesCache {
    private let storage: PersistentStorageProtocol
    private let timeToLive: TimeInterval
    private let apiType: () -> TangemAPIType

    init(
        storage: PersistentStorageProtocol,
        timeToLive: TimeInterval = Constants.timeToLive,
        apiType: @escaping () -> TangemAPIType = { FeatureStorage.instance.tangemAPIType }
    ) {
        self.storage = storage
        self.timeToLive = timeToLive
        self.apiType = apiType
    }

    /// `currency` is part of the key because `marketCap` comes back converted into it.
    func store(categories: [MarketsDTO.GeckoCategories.Category], currency: String, at date: Date = Date()) {
        let entry = Entry(apiType: apiType(), currency: currency, categories: categories, savedAt: date)

        do {
            try storage.store(value: entry, for: .coinsGeckoCategoriesCache)
        } catch {
            AppLogger.tag("Markets").error("Failed to cache gecko categories", error: error)
        }
    }

    func categories(for currency: String, at date: Date = Date()) -> [MarketsDTO.GeckoCategories.Category]? {
        guard let entry: Entry = try? storage.value(for: .coinsGeckoCategoriesCache) else {
            return nil
        }

        guard entry.apiType == apiType(), entry.currency.caseInsensitiveCompare(currency) == .orderedSame else {
            return nil
        }

        let age = date.timeIntervalSince(entry.savedAt)

        // A negative age means the clock moved backwards; treat that as expired rather than valid forever.
        guard (0 ..< timeToLive).contains(age) else {
            return nil
        }

        return entry.categories
    }

    func clear() {
        try? storage.remove(for: .coinsGeckoCategoriesCache)
    }
}

extension MarketsGeckoCategoriesCache {
    struct Entry: Codable {
        let apiType: TangemAPIType
        let currency: String
        let categories: [MarketsDTO.GeckoCategories.Category]
        let savedAt: Date
    }

    enum Constants {
        static let timeToLive: TimeInterval = 60 * 15
    }
}
