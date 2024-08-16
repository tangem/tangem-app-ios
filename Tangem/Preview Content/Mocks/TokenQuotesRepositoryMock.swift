//
//  TokenQuotesRepositoryMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class TokenQuotesRepositoryMock: TokenQuotesRepository, TokenQuotesRepositoryUpdater {
    var quotes: Quotes { [:] }
    var quotesPublisher: AnyPublisher<Quotes, Never> { .just(output: .init()) }

    func quote(for currencyId: String) async throws -> TokenQuote {
        TokenQuote(
            currencyId: currencyId,
            price: 1,
            priceChange24h: 0.3,
            priceChange7d: 3.3,
            priceChange30d: 9.3,
            currencyCode: "USD"
        )
    }

    func quote(for item: TokenItem) -> TokenQuote? { nil }
    func loadQuotes(currencyIds: [String]) -> AnyPublisher<Void, Never> { .just }
    func saveQuotes(_ quotes: [Quote], currencyCode: String) {}
    func saveQuotes(_ quotes: [TokenQuote]) {}
}
