//
//  UserCurrenciesProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct UserCurrenciesProviderMock: UserCurrenciesProviding {
    func getCurrencies(blockchain: SwappingBlockchain) -> [Currency] { [.mock] }
    func add(currency: Currency) {}
}
