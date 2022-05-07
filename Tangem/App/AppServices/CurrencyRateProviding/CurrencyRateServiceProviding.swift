//
//  CurrencyRateServiceProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol CurrencyRateServiceProviding {
    var ratesService: CurrencyRateService { get }
}

private struct CurrencyRateServiceProviderKey: InjectionKey {
    static var currentValue: CurrencyRateServiceProviding = CurrencyRateServiceProvider()
}

extension InjectedValues {
    var ratesServiceProvider: CurrencyRateServiceProviding {
        get { Self[CurrencyRateServiceProviderKey.self] }
        set { Self[CurrencyRateServiceProviderKey.self] = newValue }
    }
}
