//
//  CommonAccountRateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import CombineExt

/// Calculates the weighted average price change of a cryptocurrency portfolio based on fiat balance weights.
final class CommonAccountRateProvider {
    private let walletModelsManager: WalletModelsManager
    private let totalBalanceProvider: TotalBalanceProvider

    private let accountRateSubject = CurrentValueSubject<RateValue<AccountQuote>, Never>(.loading(cached: nil))
    private var bag = Set<AnyCancellable>()

    init(
        walletModelsManager: WalletModelsManager,
        totalBalanceProvider: TotalBalanceProvider
    ) {
        self.walletModelsManager = walletModelsManager
        self.totalBalanceProvider = totalBalanceProvider

        bind()
    }
}

// MARK: - Private

private extension CommonAccountRateProvider {
    typealias TokenQuoteAndBalance = (quote: TokenQuote?, balance: TokenBalanceType)

    func bind() {
        walletModelsManager.walletModelsPublisher
            .flatMapLatest { Self.combineQuotesWithBalances(from: $0) }
            .combineLatest(totalBalanceProvider.totalBalancePublisher)
            .withWeakCaptureOf(self)
            .sink { provider, result in
                let (quotesAndBalances, totalBalance) = result
                provider.updateAccountRate(quotesAndBalances: quotesAndBalances, totalBalance: totalBalance)
            }
            .store(in: &bag)
    }

    static func combineQuotesWithBalances(from walletModels: [any WalletModel]) -> AnyPublisher<[TokenQuoteAndBalance], Never> {
        guard walletModels.isNotEmpty else {
            // When walletModels is empty, return an empty array immediately to prevent hanging.
            return Just([]).eraseToAnyPublisher()
        }

        let balancePublishers = walletModels.map(\.fiatTotalTokenBalanceProvider.balanceTypePublisher)

        return balancePublishers
            .combineLatest()
            .map { balances in
                zip(walletModels, balances).map { (quote: $0.quote, balance: $1) }
            }
            .eraseToAnyPublisher()
    }

    func updateAccountRate(quotesAndBalances: [TokenQuoteAndBalance], totalBalance: TotalBalanceState) {
        let newRate: RateValue<AccountQuote>

        switch totalBalance {
        case .empty:
            let cachedQuote = accountRateSubject.value.quote
            newRate = .failure(cached: cachedQuote)

        case .loading:
            let cachedQuote = accountRateSubject.value.quote
            newRate = .loading(cached: cachedQuote)

        case .failed:
            let cachedQuote = accountRateSubject.value.quote
            newRate = .failure(cached: cachedQuote)

        case .loaded(let balance) where balance.isZero:
            newRate = .loaded(quote: AccountQuote(priceChange24h: 0))

        case .loaded(let balance):
            newRate = .loaded(quote: calculateWeightedPriceChange(quotesAndBalances: quotesAndBalances, totalBalance: balance))
        }

        accountRateSubject.send(newRate)
    }

    func calculateWeightedPriceChange(quotesAndBalances: [TokenQuoteAndBalance], totalBalance: Decimal) -> AccountQuote {
        let weighted24h = quotesAndBalances.reduce(into: Decimal.zero) { result, item in
            guard
                let quote = item.quote,
                let priceChange24h = quote.priceChange24h
            else {
                return
            }

            let fiatBalance = item.balance.value
            guard let fiatBalance else { return }

            let weight = (fiatBalance / totalBalance)
            result += weight * priceChange24h
        }

        return AccountQuote(priceChange24h: weighted24h)
    }
}

// MARK: - AccountRateProvider

extension CommonAccountRateProvider: AccountRateProvider {
    var accountRate: AccountRate {
        accountRateSubject.value
    }

    var accountRatePublisher: AnyPublisher<AccountRate, Never> {
        accountRateSubject.eraseToAnyPublisher()
    }
}
