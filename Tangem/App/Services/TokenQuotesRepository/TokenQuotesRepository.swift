//
//  TokenQuotesRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

typealias Quotes = [String: TokenQuote]

protocol TokenQuotesRepository: AnyObject {
    var pricesPublisher: AnyPublisher<Quotes, Never> { get }

    func quote(for item: TokenItem) -> TokenQuote?
    func loadQuotes(coinIds: [String]) -> AnyPublisher<[TokenQuote], Never>
}

private struct TokenQuotesRepositoryKey: InjectionKey {
    static var currentValue: TokenQuotesRepository = CommonTokenQuotesRepository()
}

extension InjectedValues {
    var tokenQuotesRepository: TokenQuotesRepository {
        get { Self[TokenQuotesRepositoryKey.self] }
        set { Self[TokenQuotesRepositoryKey.self] = newValue }
    }
}
