//
//  FiatRatesProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

protocol FiatRatesProviding {
    func hasRates(for currency: Currency) -> Bool
    func hasRates(for blockchain: ExchangeBlockchain) -> Bool

    func getSyncFiat(for currency: Currency, amount: Decimal) -> Decimal?
    func getSyncFiat(for blockchain: ExchangeBlockchain, amount: Decimal) -> Decimal?

    func getFiat(for currency: Currency, amount: Decimal) async throws -> Decimal
    func getFiat(for blockchain: SwappingBlockchain, amount: Decimal) async throws -> Decimal
}
