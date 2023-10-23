//
//  SwappingProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol SwappingProvider {
    func fetchQuote(items: SwappingItems, amount: String, referrer: SwappingReferrerAccount?) async throws -> SwappingQuoteDataModel
    func fetchSwappingData(
        items: SwappingItems,
        walletAddress: String,
        amount: String,
        referrer: SwappingReferrerAccount?
    ) async throws -> SwappingDataModel

    func fetchSpenderAddress(for blockchain: SwappingBlockchain) async throws -> String
}
