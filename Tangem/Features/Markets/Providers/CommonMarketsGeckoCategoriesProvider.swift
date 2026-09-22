//
//  CommonMarketsGeckoCategoriesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Loads the CoinGecko categories that drive the Crypto tag filter.
///
/// The categories themselves carry no geo restriction, but the coin list filtered by one does, so geo is resolved
/// here as well and travels with the snapshot into the list request.
final class CommonMarketsGeckoCategoriesProvider {
    private let apiService: TangemApiService
    private let geoEligibilityService: GeoEligibilityService
    private let cache: MarketsGeckoCategoriesCache
    private let currencyCode: () -> String

    init(
        apiService: TangemApiService,
        geoEligibilityService: GeoEligibilityService,
        cache: MarketsGeckoCategoriesCache,
        currencyCode: @escaping () -> String = { AppSettings.shared.selectedCurrencyCode }
    ) {
        self.apiService = apiService
        self.geoEligibilityService = geoEligibilityService
        self.cache = cache
        self.currencyCode = currencyCode
    }
}

// MARK: - MarketsGeckoCategoriesProvider

extension CommonMarketsGeckoCategoriesProvider: MarketsGeckoCategoriesProvider {
    func categories() async throws -> MarketsGeckoCategoriesSnapshot {
        // The categories request does not depend on geo, so the two run side by side;
        // geo alone can block for its whole timeout on a fresh install.
        async let regionCode = geoEligibilityService.fetchGeoIpRegionCode()

        let categories = try await loadCategories(currency: currencyCode())
        let country = await regionCode?.uppercased().nilIfEmpty

        return MarketsGeckoCategoriesSnapshot(categories: categories, country: country)
    }
}

// MARK: - Private

private extension CommonMarketsGeckoCategoriesProvider {
    func loadCategories(currency: String) async throws -> [MarketsDTO.GeckoCategories.Category] {
        do {
            let response = try await apiService.loadCoinsGeckoCategories(
                requestModel: MarketsDTO.GeckoCategories.Request(currency: currency)
            )

            cache.store(categories: response.categories, currency: currency)

            return response.categories
        } catch {
            guard !error.isCancellationError else {
                throw error
            }

            AppLogger.tag("Markets").error("Failed to load gecko categories", error: error)

            guard let cached = cache.categories(for: currency) else {
                throw error
            }

            AppLogger.tag("Markets").info("Falling back to cached gecko categories for \(currency)")

            return cached
        }
    }
}

// MARK: - Dependency injection

extension InjectedValues {
    var marketsGeckoCategoriesProvider: MarketsGeckoCategoriesProvider {
        get { Self[MarketsGeckoCategoriesProviderKey.self] }
        set { Self[MarketsGeckoCategoriesProviderKey.self] = newValue }
    }

    private struct MarketsGeckoCategoriesProviderKey: InjectionKey {
        static var currentValue: MarketsGeckoCategoriesProvider = CommonMarketsGeckoCategoriesProvider(
            apiService: InjectedValues[\.tangemApiService],
            geoEligibilityService: InjectedValues[\.geoEligibilityService],
            cache: MarketsGeckoCategoriesCache(storage: InjectedValues[\.persistentStorage])
        )
    }
}
