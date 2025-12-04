//
//  CommonFiatRateProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class CommonFiatRateProvider {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let tokenItem: TokenItem

    private var appCurrencyCodeCancellable: AnyCancellable?
    private var quotesCancellable: AnyCancellable?

    private lazy var rateSubject: CurrentValueSubject<WalletModelRate, Never> = .init(
        .loading(cached: quotesRepository.quote(for: tokenItem))
    )

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem

        bind()
        updateRate()
    }
}

// MARK: - FiatRateProvider

extension CommonFiatRateProvider: FiatRateProvider {
    var rate: WalletModelRate {
        rateSubject.value
    }

    var ratePublisher: AnyPublisher<WalletModelRate, Never> {
        rateSubject.eraseToAnyPublisher()
    }

    func updateRate() {
        guard let currencyId = tokenItem.currencyId else {
            return rateSubject.send(.custom)
        }

        rateSubject.send(.loading(cached: rateSubject.value.quote))
        quotesRepository.loadQuotes(currencyIds: [currencyId])
    }
}

// MARK: - Private

private extension CommonFiatRateProvider {
    func bind() {
        appCurrencyCodeCancellable = AppSettings.shared.$selectedCurrencyCode
            // Ignore already the selected code
            .dropFirst()
            // Ignore if the selected code is equal
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] _ in
                // Invoke immediate fiat update when currency changes (e.g. offline case)
                self?.rateSubject.send(.loading(cached: nil))
            })
            .withWeakCaptureOf(self)
            // Reload existing quotes for a new currency code
            .sink { $0.0.updateRate() }

        quotesCancellable = quotesRepository.quotesPublisher
            .withWeakCaptureOf(self)
            .sink { $0.updateWalletModelRate(quotes: $1) }
    }

    func updateWalletModelRate(quotes: Quotes) {
        let quote = tokenItem.currencyId.flatMap { quotes[$0] }

        switch quote {
        // Don't have quote because we don't have currency id
        case .none where tokenItem.currencyId == nil:
            rateSubject.send(.custom)
        // Don't have quote because of error. Update with saving the previous one
        case .none:
            rateSubject.send(.failure(cached: rate.quote))
        case .some(let quote):
            rateSubject.send(.loaded(quote: quote))
        }
    }
}
