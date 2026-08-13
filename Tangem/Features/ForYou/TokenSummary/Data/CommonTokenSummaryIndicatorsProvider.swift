//
//  CommonTokenSummaryIndicatorsProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonTokenSummaryIndicatorsProvider: TokenSummaryIndicatorsProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let mapper = TokenSummaryIndicatorsMapper()

    func loadIndicators(symbol: String) async throws -> [TokenSummaryIndicator] {
        let response = try await tangemApiService.loadCoinIndicators(requestModel: .init(symbols: [symbol]))

        // Tickers aren't unique, so keep only the asset whose symbol matches the requested one.
        let readings = response.assets
            .first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }?
            .indicators ?? []

        return mapper.mapToDomain(readings)
    }
}
