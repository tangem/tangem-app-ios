//
//  MarketsTokenModel+Deeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension MarketsTokenModel {
    /// A token deeplinks name by id alone. Everything else is fetched from the API once the details screen opens.
    static func deeplinkStub(tokenId: String) -> MarketsTokenModel {
        MarketsTokenModel(
            id: tokenId,
            name: "",
            symbol: "",
            currentPrice: nil,
            priceChangePercentage: [:],
            marketRating: nil,
            maxYieldApy: nil,
            marketCap: nil,
            isUnderMarketCapLimit: nil,
            stakingOpportunities: nil,
            networks: nil,
            restrictedForCountry: nil
        )
    }
}
