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
    private var quotesCancellable: AnyCancellable?

    private lazy var _rate: CurrentValueSubject<WalletModelRate, Never> = .init(
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
        _rate.value
    }

    var ratePublisher: AnyPublisher<WalletModelRate, Never> {
        _rate.eraseToAnyPublisher()
    }

    func updateRate() {
        guard let currencyId = tokenItem.currencyId else {
            return _rate.send(.custom)
        }

        _rate.send(.loading(cached: quotesRepository.quote(for: tokenItem)))
        quotesRepository.loadQuotes(currencyIds: [currencyId])
    }
}

// MARK: - Private

private extension CommonFiatRateProvider {
    func bind() {
        quotesCancellable = quotesRepository.quotesPublisher
            .withWeakCaptureOf(self)
            .sink { $0.updateWalletModelRate(quotes: $1) }
    }

    func updateWalletModelRate(quotes: Quotes) {
        let quote = tokenItem.currencyId.flatMap { quotes[$0] }

        switch quote {
        // Don't have quote because we don't have currency id
        case .none where tokenItem.currencyId == nil:
            _rate.send(.custom)
        // Don't have quote because of error. Update with saving the previous one
        case .none:
            _rate.send(.failure(cached: rate.quote))
        case .some(let quote):
            _rate.send(.loaded(quote: quote))
        }
    }
}
