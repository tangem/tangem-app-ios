//
//  CommonPortfolioReviewIndicatorsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonPortfolioReviewIndicatorsProvider: PortfolioReviewIndicatorsProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let mapper = TokenSummaryIndicatorsMapper()

    func loadIndicators(symbols: [String]) async throws -> [String: [TokenSummaryIndicator]] {
        guard !symbols.isEmpty else {
            return [:]
        }

        let response = try await tangemApiService.loadCoinIndicators(requestModel: .init(symbols: symbols))

        return Dictionary(
            response.assets.map { ($0.symbol.uppercased(), mapper.mapToDomain($0.indicators)) },
            uniquingKeysWith: { first, _ in first }
        )
    }
}
