//
//  ExpressSearchTokensProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

// MARK: - Protocol

protocol ExpressSearchTokensProvider {
    func search(text: String) async throws -> [MarketsTokenModel]
    func loadTrending() async throws -> [MarketsTokenModel]
}

// MARK: - Implementation

final class CommonExpressSearchTokensProvider: ExpressSearchTokensProvider {
    private let tangemApiService: TangemApiService

    private var cachedTrending: [MarketsTokenModel]?

    init(tangemApiService: TangemApiService) {
        self.tangemApiService = tangemApiService
    }

    func search(text: String) async throws -> [MarketsTokenModel] {
        guard text.count >= 2 else {
            return []
        }

        let request = MarketsDTO.General.Request(
            currency: AppSettings.shared.selectedCurrencyCode,
            offset: 0,
            limit: 50,
            interval: .day,
            order: .rating,
            search: text
        )

        let response = try await tangemApiService.loadCoinsList(requestModel: request)
        return response.tokens
    }

    func loadTrending() async throws -> [MarketsTokenModel] {
        if let cachedTrending {
            return cachedTrending
        }

        let request = MarketsDTO.General.Request(
            currency: AppSettings.shared.selectedCurrencyCode,
            offset: 0,
            limit: 20,
            interval: .day,
            order: .trending,
            search: nil
        )

        let response = try await tangemApiService.loadCoinsList(requestModel: request)
        cachedTrending = response.tokens
        return response.tokens
    }
}
