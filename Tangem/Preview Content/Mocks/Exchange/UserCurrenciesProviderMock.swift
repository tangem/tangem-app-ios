//
//  UserCurrenciesProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

struct UserCurrenciesProviderMock: UserCurrenciesProviding {
    func getCurrencies(blockchain: ExchangeBlockchain) -> [Currency] { [.mock] }
    func addCurrencyInList(currency: Currency) {}
}
