//
//  MarketsTokenDetailsDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsTokenExchangesListLoader {
    func loadExchangesList(for tokenId: TokenItemId) async throws -> [MarketsTokenDetailsExchangeItemInfo]
}

struct MarketsTokenDetailsDataProvider {
    @Injected(\.tangemApiService) private var tangemAPIService: TangemApiService

    private let mapper = MarketsTokenDetailsMapper(supportedBlockchains: SupportedBlockchains.all)

    /// Load details for selected token
    /// - Parameters:
    ///   - tokenId: Id of selected token received from backend
    ///   - baseCurrencyCode: Currency selected in App. It can be fiat or crypto currency
    func loadTokenDetails(for tokenId: TokenItemId, baseCurrencyCode: String) async throws -> MarketsTokenDetailsModel {
        let request = MarketsDTO.Coins.Request(
            tokenId: tokenId,
            currency: baseCurrencyCode,
            language: Locale.deviceLanguageCode
        )
        let result = try await tangemAPIService.loadTokenMarketsDetails(requestModel: request)
        let model = try mapper.map(response: result)
        return model
    }
}

extension MarketsTokenDetailsDataProvider: MarketsTokenExchangesListLoader {
    func loadExchangesList(for tokenId: TokenItemId) async throws -> [MarketsTokenDetailsExchangeItemInfo] {
        let result = try await tangemAPIService.loadTokenExchangesListDetails(requestModel: .init(tokenId: tokenId))
        let mapper = MarketsExchangesListMapper()
        return mapper.mapListToItemInfo(result.exchanges)
    }
}
