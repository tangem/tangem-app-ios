//
//  CurrenciesResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CurrenciesResponse: Codable {
    let currencies: [CurrenciesResponse.Currency]
}
