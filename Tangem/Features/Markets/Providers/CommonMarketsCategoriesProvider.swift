//
//  CommonMarketsCategoriesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Loads the coin categories that drive the Real assets shelf.
///
/// Geo is resolved first because the backend evaluates `restricted` against the country we send; without one it
/// answers with everything unrestricted, so the shelf fails open rather than blocking the user.
final class CommonMarketsCategoriesProvider {
    private let apiService: TangemApiService
    private let geoEligibilityService: GeoEligibilityService
    private let cache: MarketsCategoriesCache

    init(
        apiService: TangemApiService,
        geoEligibilityService: GeoEligibilityService,
        cache: MarketsCategoriesCache
    ) {
        self.apiService = apiService
        self.geoEligibilityService = geoEligibilityService
        self.cache = cache
    }
}

// MARK: - MarketsCategoriesProvider

extension CommonMarketsCategoriesProvider: MarketsCategoriesProvider {
    func categories() async throws -> MarketsCategoriesSnapshot {
        let country = await geoEligibilityService.fetchGeoIpRegionCode()?.uppercased().nilIfEmpty

        do {
            let response = try await apiService.loadCoinsCategories(
                requestModel: MarketsDTO.Categories.Request(country: country)
            )
            let categories = response.categories.sorted(by: \.displayOrder)

            if let country {
                cache.store(categories: categories, country: country)
            }

            return MarketsCategoriesSnapshot(categories: categories, country: country)
        } catch {
            AppLogger.tag("Markets").error("Failed to load coin categories", error: error)

            guard let country, let cached = cache.categories(for: country) else {
                throw error
            }

            AppLogger.tag("Markets").info("Falling back to cached coin categories for \(country)")

            return MarketsCategoriesSnapshot(categories: cached, country: country)
        }
    }
}

// MARK: - Dependency injection

extension InjectedValues {
    var marketsCategoriesProvider: MarketsCategoriesProvider {
        get { Self[MarketsCategoriesProviderKey.self] }
        set { Self[MarketsCategoriesProviderKey.self] = newValue }
    }

    private struct MarketsCategoriesProviderKey: InjectionKey {
        static var currentValue: MarketsCategoriesProvider = CommonMarketsCategoriesProvider(
            apiService: InjectedValues[\.tangemApiService],
            geoEligibilityService: InjectedValues[\.geoEligibilityService],
            cache: MarketsCategoriesCache(storage: InjectedValues[\.persistentStorage])
        )
    }
}
