//
//  FiatRatesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

class FiatRatesProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    /// Collect rates for calculate fiat balance
    @Atomic private var rates: [String: Decimal]

    // [REDACTED_TODO_COMMENT]
    private let walletModel: WalletModel

    init(walletModel: WalletModel, rates: [String: Decimal]) {
        self.walletModel = walletModel
        self.rates = rates
    }
}

// MARK: - FiatRatesProviding

extension FiatRatesProvider: FiatRatesProviding {
    func hasRates(for currency: Currency) -> Bool {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        return rates[id] != nil
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

private extension FiatRatesProvider {
    func getFiatRateFor(for currency: Currency) async throws -> Decimal {
        let id = currency.isToken ? currency.id : currency.blockchain.currencyID
        return try await getFiatRate(currencyId: id)
    }

    func getFiatRateFor(for blockchain: SwappingBlockchain) async throws -> Decimal {
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

        updateRate(for: currencyId, with: currencyRate)

        return currencyRate
    }

    func mapToFiat(amount: Decimal, rate: Decimal) -> Decimal {
        let fiatValue = amount * rate
        if fiatValue == 0 {
            return 0
        }

        return max(fiatValue, 0.01).rounded(scale: 2, roundingMode: .plain)
    }

    func updateRate(for currencyId: String, with value: Decimal) {
        rates[currencyId] = value

        rates.forEach { key, value in
            walletModel.rates.updateValue(value, forKey: key)
        }
    }
}
