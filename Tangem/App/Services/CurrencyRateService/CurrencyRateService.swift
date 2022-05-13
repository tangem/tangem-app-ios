//
//  CurrencyRateService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

protocol CurrencyRateService: ScanListener {
    var selectedCurrencyCode: String { get set }
    var selectedCurrencyCodePublisher: Published<String>.Publisher { get }
    
    func rates(for coinIds: [String]) -> AnyPublisher<[String: Decimal], Never>
    func baseCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], MoyaError>
}

private struct CurrencyRateServiceKey: InjectionKey {
    static var currentValue: CurrencyRateService = CommonCurrencyRateService()
}

extension InjectedValues {
    var currencyRateService: CurrencyRateService {
        get { Self[CurrencyRateServiceKey.self] }
        set { Self[CurrencyRateServiceKey.self] = newValue }
    }
}
