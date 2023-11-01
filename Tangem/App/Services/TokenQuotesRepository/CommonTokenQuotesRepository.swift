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
    private var loadingQueue = PassthroughSubject<QueueItem, Never>()
    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
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
        AppLog.shared.debug("Request loading quotes for ids: \(currencyIds)")

        let outputPublisher = PassthroughSubject<Void, Never>()
        let item = QueueItem(ids: currencyIds, didLoadPublisher: outputPublisher)
        loadingQueue.send(item)

        // Return the outputPublisher that the requester knew when quotes were loaded
        return outputPublisher.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonTokenQuotesRepository {
    func bind() {
        AppSettings.shared.$selectedCurrencyCode
            // Ignore already the selected code
            .dropFirst()
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            // Ignore if the selected code is equal
            .removeDuplicates()
            .withLatestFrom(_quotes)
            .withWeakCaptureOf(self)
            // Reload existing quotes for a new currency code
            .flatMapLatest { repository, quotes in
                let currencyIds = Array(quotes.keys)
                return repository.loadQuotes(currencyIds: currencyIds)
            }
            .sink()
            .store(in: &bag)

        loadingQueue
            .collect(debouncedTime: 0.3, scheduler: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .flatMap { repository, items in
                let ids = items.flatMap { $0.ids }

                return repository
                    .loadAndSaveQuotes(currencyIds: ids)
                    .map { items }
            }
            .sink(receiveCompletion: { completion in
                guard case .failure(let error) = completion else {
                    return
                }
                
                AppLog.shared.debug("Loading quotes catch error")
                AppLog.shared.error(error: error, params: [:])
            }, receiveValue: { items in
                // Send the event that quotes for currencyIds have been loaded
                items.forEach { $0.didLoadPublisher.send(()) }
            })
            .store(in: &bag)
    }

    func loadAndSaveQuotes(currencyIds: [String]) -> AnyPublisher<Void, Error> {
        AppLog.shared.debug("Start loading quotes for ids: \(currencyIds)")

        let currencyCode = AppSettings.shared.selectedCurrencyCode
        // We get here currencyIds. But on in the API model we named it like coinIds
        let request = QuotesDTO.Request(coinIds: currencyIds, currencyId: currencyCode)

        return tangemApiService
            .loadQuotes(requestModel: request)
            .map { [weak self] quotes in
                AppLog.shared.debug("Finish loading quotes for ids: \(currencyIds)")
                self?.saveQuotes(quotes, currencyCode: currencyCode)
                return ()
            }
            .eraseToAnyPublisher()
    }

    func saveQuotes(_ quotes: [Quote], currencyCode: String) {
        let quotes = quotes.map { quote in
            TokenQuote(
                currencyId: quote.id,
                // We round price change for the user friendly size
                change: quote.priceChange?.rounded(scale: 1),
                price: quote.price,
                currencyCode: currencyCode
            )
        }

        var current = _quotes.value

        quotes.forEach { quote in
            current[quote.currencyId] = quote
        }

        _quotes.send(current)
    }
}

extension CommonTokenQuotesRepository {
    struct QueueItem {
        let ids: [String]
        let didLoadPublisher: PassthroughSubject<Void, Never>
    }
}
