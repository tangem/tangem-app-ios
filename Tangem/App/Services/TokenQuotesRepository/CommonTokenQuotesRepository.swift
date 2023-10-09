//
//  CommonTokenQuotesRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CommonTokenQuotesRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var _quotes: CurrentValueSubject<Quotes, Never> = .init([:])
    private var currencyCode: String { AppSettings.shared.selectedCurrencyCode }
    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
    }

    private func bind() {
        AppSettings.shared.$selectedCurrencyCode
            .sink(receiveValue: { [weak self] _ in
                self?._quotes.value.removeAll()
            })
            .store(in: &bag)
    }
}

// MARK: - TokenQuotesRepository

extension CommonTokenQuotesRepository: TokenQuotesRepository {
    var quotes: Quotes {
        return _quotes.value
    }

    var quotesPublisher: AnyPublisher<Quotes, Never> {
        _quotes.eraseToAnyPublisher()
    }

    func quote(for currencyId: String) async throws -> TokenQuote {
        var quote = quotes[currencyId]

        if quote == nil {
            await loadQuotes(currencyIds: [currencyId])
            quote = quotes[currencyId]
        }

        guard let quote else {
            throw CommonError.noData
        }

        return quote
    }

    func loadQuotes(currencyIds: [String]) -> AnyPublisher<Void, Never> {
        // We get here currencyIds. But on in the API model we named it like coinIds
        let request = QuotesDTO.Request(coinIds: currencyIds, currencyId: currencyCode)

        return tangemApiService
            .loadQuotes(requestModel: request)
            .replaceError(with: [])
            .map { quotes -> [TokenQuote] in
                quotes.map { quote in
                    TokenQuote(
                        currencyId: quote.id,
                        // We round price change for the user friendly size
                        change: quote.priceChange?.rounded(scale: 2),
                        price: quote.price,
                        currencyCode: request.currencyId
                    )
                }
            }
            .handleEvents(receiveOutput: { [weak self] quotes in
                guard let self else { return }

                var current = _quotes.value

                quotes.forEach { quote in
                    current[quote.currencyId] = quote
                }

                _quotes.send(current)
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
