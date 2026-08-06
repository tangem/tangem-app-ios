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

    /// A portfolio can hold more tokens than one request accepts, so the symbols travel in batches.
    func loadIndicators(symbols: [String]) async throws -> [String: [TokenSummaryIndicator]] {
        guard !symbols.isEmpty else {
            return [:]
        }

        var result: [String: [TokenSummaryIndicator]] = [:]

        for batch in symbols.chunked(into: CoinIndicatorsDTO.symbolsPerRequestLimit) {
            let response = try await tangemApiService.loadCoinIndicators(requestModel: .init(symbols: batch))

            // Tickers aren't unique, so the first asset reported for a symbol wins.
            for asset in response.assets where result[asset.symbol.uppercased()] == nil {
                result[asset.symbol.uppercased()] = mapper.mapToDomain(asset.indicators)
            }
        }

        return result
    }
}

// MARK: - Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0 ..< Swift.min($0 + size, count)]) }
    }
}
