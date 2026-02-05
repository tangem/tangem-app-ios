//
//  CommonTokenQuotesRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import TangemFoundation

class CommonTokenQuotesRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var _quotes: CurrentValueSubject<Quotes, Never> = .init([:])
    private var loadingQueue = PassthroughSubject<QueueItem, Never>()
    private var bag: Set<AnyCancellable> = []
    private let storage = CachesDirectoryStorage(file: .cachedQuotes)
    private let lock = OSAllocatedUnfairLock()

    init() {
        bind()

        try? _quotes.send(storage.value())
    }
}

// MARK: - TokenQuotesRepository

extension CommonTokenQuotesRepository: TokenQuotesRepository {
    var quotes: Quotes {
        _quotes.value
    }

    var quotesPublisher: AnyPublisher<Quotes, Never> {
        _quotes.eraseToAnyPublisher()
    }

    func fetchFreshQuoteFor(currencyId: String, shouldUpdateCache: Bool) async throws -> TokenQuote {
        let quotes = await loadQuotes(currencyIds: [currencyId])

        guard let quote = quotes[currencyId] else {
            throw CommonError.noData
        }

        if shouldUpdateCache {
            saveQuotes([quote])
        }

        return quote
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

    @discardableResult
    func loadQuotes(currencyIds: [String]) -> AnyPublisher<[String: TokenQuote], Never> {
        AppLogger.info(self, "Request loading quotes for ids: \(currencyIds)")

        let outputPublisher = PassthroughSubject<[String: TokenQuote], Never>()
        let item = QueueItem(ids: currencyIds, didLoadPublisher: outputPublisher)
        loadingQueue.send(item)

        // Return the outputPublisher that the requester knew when quotes were loaded
        return outputPublisher.eraseToAnyPublisher()
    }
}

// MARK: - TokenQuotesRepositoryUpdater

extension CommonTokenQuotesRepository: TokenQuotesRepositoryUpdater {
    func saveQuotes(_ quotes: [TokenQuote]) {
        lock {
            var current = _quotes.value

            quotes.forEach { quote in
                current[quote.currencyId] = quote
            }

            _quotes.send(current)
            storage.store(value: current)
        }
    }
}

// MARK: - Private

private extension CommonTokenQuotesRepository {
    func bind() {
        loadingQueue
            .collect(debouncedTime: 0.3, scheduler: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .flatMap { repository, items in
                let ids = items.flatMap { $0.ids }

                return repository
                    .loadAndSaveQuotes(currencyIds: ids)
                    .map { (items, $0) }
            }
            .withWeakCaptureOf(self)
            .sink(receiveValue: { repository, items in
                let (queueItems, loadedRates) = items
                // Send the event that quotes for currencyIds have been loaded
                queueItems.forEach { queueItem in
                    let results: [String: TokenQuote] = queueItem.ids.reduce(into: [:]) {
                        $0[$1] = loadedRates[$1]
                    }

                    queueItem.didLoadPublisher.send(results)
                }
            })
            .store(in: &bag)

        // Reload user quotes
        NotificationCenter.default
            // We can't use didBecomeActive because of NFC interaction app state changes
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .filter { [weak self] _ in
                guard let self else { return false }

                return !userWalletRepository.isLocked
            }
            .withWeakCaptureOf(self)
            .flatMap { repository, _ in
                let userWallets = repository.userWalletRepository.models
                let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWallets)
                let userCurrencyIds = walletModels.compactMap(\.tokenItem.currencyId).unique()
                return repository.loadQuotes(currencyIds: userCurrencyIds)
            }
            .sink()
            .store(in: &bag)
    }

    func loadAndSaveQuotes(currencyIds: [String]) -> AnyPublisher<[String: TokenQuote], Never> {
        AppLogger.info(self, "Start loading quotes for ids: \(currencyIds)")

        let currencyCode = AppSettings.shared.selectedCurrencyCode

        let fields: [QuotesDTO.Request.Fields] = [.price, .priceChange24h, .lastUpdatedAt, .priceChange7d, .priceChange30d]

        // We get here currencyIds. But on in the API model we named it like coinIds
        let request = QuotesDTO.Request(
            coinIds: currencyIds,
            currencyId: currencyCode,
            fields: fields
        )

        return tangemApiService
            .loadQuotes(requestModel: request)
            .map { [weak self] quotes in
                AppLogger.info(self, "Finish loading quotes for ids: \(currencyIds)")
                let quotes = quotes.compactMap {
                    self?.mapToTokenQuote(quote: $0, currencyCode: currencyCode)
                }
                self?.saveQuotes(quotes)
                return quotes.reduce(into: [:]) { $0[$1.currencyId] = $1 }
            }
            .catch { [weak self] error -> AnyPublisher<[String: TokenQuote], Never> in
                AppLogger.error(self, "Loading quotes catch error", error: error)
                return Just([:]).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func mapToTokenQuote(quote: Quote, currencyCode: String) -> TokenQuote {
        TokenQuote(
            currencyId: quote.id,
            price: quote.price,
            priceChange24h: quote.priceChange,
            priceChange7d: quote.priceChange7d,
            priceChange30d: quote.priceChange30d,
            currencyCode: currencyCode
        )
    }
}

extension CommonTokenQuotesRepository: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

extension CommonTokenQuotesRepository {
    struct QueueItem {
        let ids: [String]
        let didLoadPublisher: PassthroughSubject<[String: TokenQuote], Never>
    }
}
