//
//  FiatRatesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

class FiatRatesProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    /// Collect rates for calculate fiat balance
    private var rates: [String: Decimal]

    init(rates: [String: Decimal]) {
        self.rates = rates
    }
}

// MARK: - FiatRatesProviding

extension FiatRatesProvider: FiatRatesProviding {
    func hasRates(for currency: Currency) -> Bool {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        return rates[id] != nil
    }

    func hasRates(for blockchain: ExchangeBlockchain) -> Bool {
        return rates[blockchain.currencyID] != nil
    }

    func getSyncFiat(for currency: Currency, amount: Decimal) -> Decimal? {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        if let rate = rates[id] {
            return mapToFiat(amount: amount, rate: rate)
        }

        return nil
    }

    func getSyncFiat(for blockchain: ExchangeBlockchain, amount: Decimal) -> Decimal? {
        if let rate = rates[blockchain.currencyID] {
            return mapToFiat(amount: amount, rate: rate)
        }

        return nil
    }

    func getFiat(for currency: Currency, amount: Decimal) async throws -> Decimal {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        let rate = try await getFiatRate(currencyId: id)
        return mapToFiat(amount: amount, rate: rate)
    }

    func getFiat(for blockchain: ExchangeBlockchain, amount: Decimal) async throws -> Decimal {
        let rate = try await getFiatRate(currencyId: blockchain.currencyID)
        return mapToFiat(amount: amount, rate: rate)
    }
}

// MARK: - Private

private extension FiatRatesProvider {
    func getFiatRateFor(for currency: Currency) async throws -> Decimal {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        return try await getFiatRate(currencyId: id)
    }

    func getFiatRateFor(for blockchain: ExchangeBlockchain) async throws -> Decimal {
        try await getFiatRate(currencyId: blockchain.currencyID)
    }

    func getFiatRate(currencyId: String) async throws -> Decimal {
        var currencyRate = rates[currencyId]

        if currencyRate == nil {
            let loadedRates = try await tangemApiService.loadRates(for: [currencyId]).async()
            currencyRate = loadedRates[currencyId]
        }

        guard let currencyRate else {
            throw CommonError.noData
        }

        rates[currencyId] = currencyRate

        return currencyRate
    }

    func mapToFiat(amount: Decimal, rate: Decimal) -> Decimal {
        let fiatValue = amount * rate
        if fiatValue == 0 {
            return 0
        }

        return max(fiatValue, 0.01).rounded(scale: 2, roundingMode: .plain)
    }
}
