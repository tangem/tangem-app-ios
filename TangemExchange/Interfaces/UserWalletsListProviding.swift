//
//  UserWalletsListProviding.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol UserWalletsListProviding {
    func getUserCurrencies(blockchain: ExchangeBlockchain) -> [Currency]
    func saveCurrencyInUserList(currency: Currency)
}
