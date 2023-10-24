//
//  SwappingRatesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

class SwappingRatesProvider {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    /// Collect quotes for calculate fiat balance
    private var quotes: Quotes {
        return quotesRepository.quotes
    }
}

// MARK: - FiatRatesProviding

extension SwappingRatesProvider: FiatRatesProviding {
    func hasRates(for currency: Currency) -> Bool {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        return quotes[id] != nil
    }

    func hasRates(for blockchain: TangemSwapping.SwappingBlockchain) -> Bool {
        return quotes[blockchain.currencyID] != nil
    }

    func getFiat(for currency: Currency, amount: Decimal) -> Decimal? {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        if let rate = quotes[id]?.price {
            return mapToFiat(amount: amount, rate: rate)
        }

        return nil
    }

    func getFiat(for blockchain: TangemSwapping.SwappingBlockchain, amount: Decimal) -> Decimal? {
        if let rate = quotes[blockchain.currencyID]?.price {
            return mapToFiat(amount: amount, rate: rate)
        }

        return nil
    }

    func getFiat(for currency: Currency, amount: Decimal) async throws -> Decimal {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        let rate = try await quotesRepository.quote(for: id).price
        return mapToFiat(amount: amount, rate: rate)
    }

    func getFiat(for blockchain: SwappingBlockchain, amount: Decimal) async throws -> Decimal {
        let rate = try await quotesRepository.quote(for: blockchain.currencyID).price
        return mapToFiat(amount: amount, rate: rate)
    }

    func getFiat(for currencies: [Currency: Decimal]) async throws -> [Currency: Decimal] {
        let ids = currencies.keys.map { $0.isToken ? $0.id : $0.blockchain.currencyID }
        _ = await quotesRepository.loadQuotes(currencyIds: ids)

        return currencies.reduce(into: [:]) { result, args in
            let (currency, amount) = args
            if let fiat = getFiat(for: currency, amount: amount) {
                result[currency] = fiat
            }
        }
    }
}

// MARK: - Private

private extension SwappingRatesProvider {
    func mapToFiat(amount: Decimal, rate: Decimal) -> Decimal {
        let fiatValue = amount * rate
        if fiatValue == 0 {
            return 0
        }

        return max(fiatValue, 0.01).rounded(scale: 2, roundingMode: .plain)
    }
}
