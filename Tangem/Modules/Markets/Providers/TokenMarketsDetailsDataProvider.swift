//
//  TokenMarketsDetailsDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class TokenMarketsDetailsDataProvider {
    @Injected(\.tangemApiService) private var tangemAPIService: TangemApiService

    func loadTokenMarketsDetails(for tokenId: TokenItemId) async throws -> TokenMarketsDetailsModel {
        let request = await MarketsDTO.Coins.Request(
            tokenId: tokenId,
            currency: AppSettings.shared.selectedCurrencyCode,
            language: Locale.current.identifier
        )
        let result = try await tangemAPIService.loadTokenMarketsDetails(requestModel: request)
        return .init(marketsDTO: result)
    }
}
