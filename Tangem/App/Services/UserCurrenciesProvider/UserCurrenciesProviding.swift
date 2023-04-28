//
//  UserCurrenciesProviding.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

public protocol UserCurrenciesProviding {
    func getCurrencies(blockchain: SwappingBlockchain) -> [Currency]
}
