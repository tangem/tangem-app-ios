//
//  TransactionHistoryAuxDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol TransactionHistoryAuxDataStorage {
    // MARK: Express providers

    func providers() async throws -> [TransactionHistoryAuxDataCachedValue<ExpressProvider>]
    func saveProviders(_ providers: [ExpressProvider]) async throws

    // MARK: Fiat currencies

    func fiatCurrencies() async throws -> [TransactionHistoryAuxDataCachedValue<OnrampFiatCurrency>]
    func saveFiatCurrencies(_ currencies: [OnrampFiatCurrency]) async throws

    // MARK: Crypto currencies

    func cryptoCurrencies() async throws -> [TransactionHistoryAuxDataCachedValue<TokenItem>]
    func saveCryptoCurrencies(_ tokenItems: [TokenItem]) async throws
}
