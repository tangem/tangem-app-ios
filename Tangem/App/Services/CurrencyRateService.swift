//
//  CurrencyRateService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk

class CurrencyRateService {
    @Storage(type: StorageType.selectedCurrencyCode, defaultValue: "USD")
    var selectedCurrencyCode: String {
        didSet {
            selectedCurrencyCodePublished = selectedCurrencyCode
        }
    }
    
    @Published var selectedCurrencyCodePublished: String = ""
    
    var card: Card?
    
    let provider = MoyaProvider<TangemApiTarget>()
    
    internal init() {}
    
    deinit {
        print("CurrencyRateService deinit")
    }
    
    func baseCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], MoyaError> {
        provider
            .requestPublisher(TangemApiTarget(type: .currencies, card: card))
            .filterSuccessfulStatusCodes()
            .map(CurrenciesResponse.self)
            .map { $0.currencies.sorted(by: { $0.name < $1.name } ) }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
    
    func rates(for coinIds: [String]) -> AnyPublisher<[String: Decimal], Never> {
        return provider
            .requestPublisher(TangemApiTarget(type: .rates(coinIds: coinIds, currencyId: selectedCurrencyCode), card: card))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RatesResponse.self)
            .map { $0.rates }
            .tryMap { dictionary in
                Dictionary(uniqueKeysWithValues: dictionary.map {
                    ($0.key, $0.value.rounded(scale: 2, roundingMode: .plain))
                })
            }
            .catch { _ in Empty(completeImmediately: true) }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
}
