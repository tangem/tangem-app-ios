//
//  MarketsCategoriesCache.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A fallback for a failed `/v1/coins/categories`, not a read-through cache: `MarketsCategoriesProvider` requests
/// fresh data every time and only reads the stored payload once that request fails.
final class MarketsCategoriesCache {
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

    /// `country` is deliberately non-optional: a payload fetched without one comes back with every category
    /// unrestricted, and persisting that would let a single launch with unresolved geo poison the fallback.
    func store(categories: [MarketsDTO.Categories.Category], country: String, at date: Date = Date()) {
        let entry = Entry(apiType: apiType(), country: country, categories: categories, savedAt: date)

        do {
            try storage.store(value: entry, for: .coinsCategoriesCache)
        } catch {
            AppLogger.tag("Markets").error("Failed to cache coin categories", error: error)
        }
    }

    func categories(for country: String, at date: Date = Date()) -> [MarketsDTO.Categories.Category]? {
        guard let entry: Entry = try? storage.value(for: .coinsCategoriesCache) else {
            return nil
        }

        // Category ids are assigned per environment, so a payload fetched before a tester switched the API host
        // would hand the shelf ids the current backend knows nothing about.
        guard entry.apiType == apiType(), entry.country == country else {
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
        try? storage.remove(for: .coinsCategoriesCache)
    }
}

extension MarketsCategoriesCache {
    struct Entry: Codable {
        let apiType: TangemAPIType
        let country: String
        let categories: [MarketsDTO.Categories.Category]
        let savedAt: Date
    }

    enum Constants {
        static let timeToLive: TimeInterval = 60 * 15
    }
}
