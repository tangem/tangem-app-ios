//
//  PriceChangeProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class TokenQuotesRepositoryMock: TokenQuotesRepository {
    var pricesPublisher: AnyPublisher<Quotes, Never> { .just(output: .init()) }

    func quote(for item: TokenItem) -> TokenQuote? { nil }
    func loadQuotes(coinIds: [String]) -> AnyPublisher<[TokenQuote], Never> { .just(output: []) }
}
