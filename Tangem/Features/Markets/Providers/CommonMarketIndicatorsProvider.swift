//
//  CommonMarketIndicatorsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonMarketIndicatorsProvider {
    private let apiService: TangemApiService

    init(apiService: TangemApiService) {
        self.apiService = apiService
    }
}

// MARK: - MarketIndicatorsProvider

extension CommonMarketIndicatorsProvider: MarketIndicatorsProvider {
    func indicators(currency: String) async throws -> MarketIndicators {
        let response = try await apiService.loadMarketIndicators(
            requestModel: MarketsDTO.MarketIndicators.Request(
                currency: currency,
                language: Locale.deviceLanguageCode(withRegion: false)
            )
        )

        return MarketIndicators(
            totalMarketCap: response.totalMarketCap,
            marketCapChangePercentage24h: response.marketCapChangePercentage24H,
            fearGreed: indicator(value: response.fearGreedValue, classification: response.fearGreedClassification),
            altcoinIndex: indicator(value: response.altcoinIndexValue, classification: response.altcoinIndexClassification)
        )
    }
}

// MARK: - Private

private extension CommonMarketIndicatorsProvider {
    func indicator(value: Decimal?, classification: String?) -> MarketIndicators.Indicator? {
        value.map { MarketIndicators.Indicator(value: $0, classification: classification?.nilIfEmpty) }
    }
}

// MARK: - Dependency injection

extension InjectedValues {
    var marketIndicatorsProvider: MarketIndicatorsProvider {
        get { Self[MarketIndicatorsProviderKey.self] }
        set { Self[MarketIndicatorsProviderKey.self] = newValue }
    }

    private struct MarketIndicatorsProviderKey: InjectionKey {
        static var currentValue: MarketIndicatorsProvider = CommonMarketIndicatorsProvider(
            apiService: InjectedValues[\.tangemApiService]
        )
    }
}
