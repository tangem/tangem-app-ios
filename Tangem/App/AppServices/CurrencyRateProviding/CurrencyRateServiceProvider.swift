//
//  CurrencyRateServiceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CurrencyRateServiceProvider: CurrencyRateServiceProviding {
    var ratesService: CurrencyRateService = .init()
}
