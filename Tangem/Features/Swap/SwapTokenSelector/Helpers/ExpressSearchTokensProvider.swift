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
}

// MARK: - Implementation

final class CommonExpressSearchTokensProvider: ExpressSearchTokensProvider {
    private let tangemApiService: TangemApiService

    init(tangemApiService: TangemApiService) {
        self.tangemApiService = tangemApiService
    }

    func search(text: String) async throws -> [MarketsTokenModel] {
        guard text.count >= 2 else {
            return []
        }

        // Use Markets API for searching - same as Markets list
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
}
