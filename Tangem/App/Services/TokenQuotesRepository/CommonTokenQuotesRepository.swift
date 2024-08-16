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
import TangemFoundation

class CommonTokenQuotesRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

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
        _quotes.value
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
}

extension CommonTokenQuotesRepository: TokenQuotesRepositoryUpdater {
    func loadQuotes(currencyIds: [String]) -> AnyPublisher<Void, Never> {
        log("Request loading quotes for ids: \(currencyIds)")

        let outputPublisher = PassthroughSubject<Void, Never>()
        let item = QueueItem(ids: currencyIds, didLoadPublisher: outputPublisher)
        loadingQueue.send(item)

        // Return the outputPublisher that the requester knew when quotes were loaded
        return outputPublisher.eraseToAnyPublisher()
    }

    func saveQuotes(_ quotes: [TokenQuote]) {
        var current = _quotes.value

        quotes.forEach { quote in
            current[quote.currencyId] = quote
        }

        _quotes.send(current)
    }
}

// MARK: - Private

private extension CommonTokenQuotesRepository {
    func bind() {
        AppSettings.shared.$selectedCurrencyCode
            // Ignore already the selected code
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
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
            .sink(receiveValue: { items in
                // Send the event that quotes for currencyIds have been loaded
                items.forEach { $0.didLoadPublisher.send(()) }
            })
            .store(in: &bag)

        NotificationCenter.default
            // We can't use didBecomeActive because of NFC interaction app state changes
            .publisher(for: UIApplication.willEnterForegroundNotification)
            // We need to add small delay in order to catch UserWalletRepository lock event
            // If lock event occur - we can clear repository and no need to reload all saved items
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .flatMap { repository, _ in
                // Reload saved quotes
                let idsToLoad: [String] = Array(repository.quotes.keys)
                return repository.loadQuotes(currencyIds: idsToLoad)
            }
            .sink()
            .store(in: &bag)

        userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .sink { repository, event in
                if case .locked = event {
                    repository.clearRepository()
                }
            }
            .store(in: &bag)
    }

    func loadAndSaveQuotes(currencyIds: [String]) -> AnyPublisher<Void, Never> {
        log("Start loading quotes for ids: \(currencyIds)")

        let currencyCode = AppSettings.shared.selectedCurrencyCode

        let fields: [QuotesDTO.Request.Fields] = FeatureStorage().useDevApi ? [.price, .priceChange24h, .lastUpdatedAt, .priceChange7d, .priceChange30d] : [.price, .priceChange24h]

        // We get here currencyIds. But on in the API model we named it like coinIds
        let request = QuotesDTO.Request(
            coinIds: currencyIds,
            currencyId: currencyCode,
            fields: fields
        )

        return tangemApiService
            .loadQuotes(requestModel: request)
            .map { [weak self] quotes in
                self?.log("Finish loading quotes for ids: \(currencyIds)")
                self?.saveQuotes(quotes, currencyCode: currencyCode)
                return ()
            }
            .catch { [weak self] error in
                self?.log("Loading quotes catch error")
                AppLog.shared.error(error: error, params: [:])
                return Just(())
            }
            .eraseToAnyPublisher()
    }

    func saveQuotes(_ quotes: [Quote], currencyCode: String) {
        let quotes = quotes.map { quote in
            TokenQuote(
                currencyId: quote.id,
                price: quote.price,
                priceChange24h: quote.priceChange,
                priceChange7d: quote.priceChange7d,
                priceChange30d: quote.priceChange30d,
                currencyCode: currencyCode
            )
        }

        saveQuotes(quotes)
    }

    func clearRepository() {
        log("Start repository cleanup")
        _quotes.value.removeAll()
    }

    func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[CommonTokenQuotesRepository] \(message())")
    }
}

extension CommonTokenQuotesRepository {
    struct QueueItem {
        let ids: [String]
        let didLoadPublisher: PassthroughSubject<Void, Never>
    }
}
