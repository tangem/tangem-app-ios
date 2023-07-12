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
    @Injected(\.ratesRepository) private var ratesRepository: RatesRepository

    /// Collect rates for calculate fiat balance
    private var rates: [String: Decimal] {
        return ratesRepository.rates
    }
}

// MARK: - FiatRatesProviding

extension SwappingRatesProvider: FiatRatesProviding {
    func hasRates(for currency: Currency) -> Bool {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        return rates[id] != nil
    }

    func hasRates(for blockchain: TangemSwapping.SwappingBlockchain) -> Bool {
        return rates[blockchain.currencyID] != nil
    }

    func getSyncFiat(for currency: Currency, amount: Decimal) -> Decimal? {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        if let rate = rates[id] {
            return mapToFiat(amount: amount, rate: rate)
        }

        return nil
    }

    func getSyncFiat(for blockchain: TangemSwapping.SwappingBlockchain, amount: Decimal) -> Decimal? {
        if let rate = rates[blockchain.currencyID] {
            return mapToFiat(amount: amount, rate: rate)
        }

        return nil
    }

    func getFiat(for currencies: [Currency: Decimal]) async throws -> [Currency: Decimal] {
        let ids = currencies.keys.map { $0.isToken ? $0.id : $0.blockchain.currencyID }
        try await updateFiatRates(for: Set(ids))

        return currencies.reduce(into: [:]) { result, args in
            let (currency, amount) = args
            if let fiat = getSyncFiat(for: currency, amount: amount) {
                result[currency] = fiat
            }
        }
    }

    func getFiat(for currency: Currency, amount: Decimal) async throws -> Decimal {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        let rate = try await getFiatRate(currencyId: id)
        return mapToFiat(amount: amount, rate: rate)
    }

    func getFiat(for blockchain: SwappingBlockchain, amount: Decimal) async throws -> Decimal {
        let rate = try await getFiatRate(currencyId: blockchain.currencyID)
        return mapToFiat(amount: amount, rate: rate)
    }
}

// MARK: - Private

private extension SwappingRatesProvider {
    func getFiatRateFor(for currency: Currency) async throws -> Decimal {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        return try await getFiatRate(currencyId: id)
    }

    func getFiatRateFor(for blockchain: SwappingBlockchain) async throws -> Decimal {
        try await getFiatRate(currencyId: blockchain.currencyID)
    }

    func getFiatRate(currencyId: String) async throws -> Decimal {
        return try await ratesRepository.rate(for: currencyId)
    }

    func updateFiatRates(for currencyIDs: Set<String>) async throws {
        let savedRateIDs = Set(rates.keys)
        let needToLoadRates = currencyIDs.subtracting(savedRateIDs)

        // Nothing need to load. Just return cached rates
        guard !needToLoadRates.isEmpty else {
            return
        }

        let loadedRates = try await tangemApiService.loadRates(for: Array(needToLoadRates)).async()

        loadedRates.forEach { id, rate in
            updateRate(for: id, with: rate)
        }
    }

    func mapToFiat(amount: Decimal, rate: Decimal) -> Decimal {
        let fiatValue = amount * rate
        if fiatValue == 0 {
            return 0
        }

        return max(fiatValue, 0.01).rounded(scale: 2, roundingMode: .plain)
    }
}
