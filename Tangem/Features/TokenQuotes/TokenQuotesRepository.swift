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
    var quotes: Quotes { get }
    var quotesPublisher: AnyPublisher<Quotes, Never> { get }

    func quote(for currencyId: String) async throws -> TokenQuote
    /// Use it just for load and save quotes in the cache
    /// For get updates make a subscribe to quotesPublisher
    func loadQuotes(currencyIds: [String]) -> AnyPublisher<[String: TokenQuote], Never>
}

extension TokenQuotesRepository {
    func quote(for id: String?) -> TokenQuote? {
        guard let id else {
            return nil
        }

        return quotes[id]
    }

    func quote(for item: TokenItem) -> TokenQuote? {
        return quote(for: item.currencyId)
    }

    func loadQuotes(currencyIds: [String]) async {
        _ = try? await loadQuotes(currencyIds: currencyIds).async()
    }
}

protocol TokenQuotesRepositoryUpdater: AnyObject {
    func saveQuotes(_ quotes: [TokenQuote])
    func saveQuote(_ quote: TokenQuote)
}

extension TokenQuotesRepositoryUpdater {
    func saveQuote(_ quote: TokenQuote) {
        saveQuotes([quote])
    }
}

private struct TokenQuotesRepositoryKey: InjectionKey {
    static var currentValue: TokenQuotesRepository & TokenQuotesRepositoryUpdater = CommonTokenQuotesRepository()
}

extension InjectedValues {
    var quotesRepositoryUpdater: TokenQuotesRepositoryUpdater { _quotesRepository }

    var quotesRepository: TokenQuotesRepository { _quotesRepository }

    private var _quotesRepository: TokenQuotesRepository & TokenQuotesRepositoryUpdater {
        get { Self[TokenQuotesRepositoryKey.self] }
        set { Self[TokenQuotesRepositoryKey.self] = newValue }
    }

    static func setTokenQuotesRepository(_ newRepository: TokenQuotesRepository & TokenQuotesRepositoryUpdater) {
        InjectedValues[\._quotesRepository] = newRepository
    }
}
