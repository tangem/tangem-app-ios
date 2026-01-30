//
//  MarketsRelatedTokenNewsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsRelatedTokenNewsProvider {
    // MARK: - Injected Services

    @Injected(\.tangemApiService) private var tangemAPIService: TangemApiService

    // MARK: - Protocol Implementation

    func loadRelatedNews(for tokenId: TokenItemId) async throws -> NewsDTO.List.Response {
        let requestModel = NewsDTO.List.Request(
            limit: Constants.newsLimitOnPage,
            lang: Locale.newsLanguageCode,
            tokenIds: [tokenId]
        )
        return try await tangemAPIService.loadNewsList(requestModel: requestModel)
    }
}

extension MarketsRelatedTokenNewsProvider {
    enum Constants {
        static let newsLimitOnPage: Int = 10
    }
}
