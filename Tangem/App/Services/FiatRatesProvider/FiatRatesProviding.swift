//
//  FiatRatesProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

protocol FiatRatesProviding {
    func hasRates(for currency: Currency) -> Bool
    func getFiat(for currency: Currency, amount: Decimal) async throws -> Decimal
    func getFiat(for blockchain: ExchangeBlockchain, amount: Decimal) async throws -> Decimal
}
