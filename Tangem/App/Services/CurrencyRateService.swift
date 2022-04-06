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

struct FiatResponse: Codable {
    let currencies: [FiatCurrency]
}

struct FiatCurrency: Codable, Identifiable, CustomStringConvertible {
    let id: String
    let code: String
    let name: String
    let unit: String
    
    var description: String {
        let localizedName = Locale.current.localizedString(forCurrencyCode: code)?.capitalizingFirstLetter() ?? name
        return "\(localizedName) (\(code)) — \(unit)"
    }
}

struct RateInfoResponse: Codable {
    let prices: [String: Decimal]
}


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
    
    internal init() {
        
    }
    
    deinit {
        print("CurrencyRateService deinit")
    }
    
    func baseCurrencies() -> AnyPublisher<[FiatCurrency], MoyaError> {
        provider
            .requestPublisher(TangemApiTarget(type: .baseCurrencies, card: card))
            .filterSuccessfulStatusCodes()
            .map(FiatResponse.self)
            .map { $0.currencies.sorted(by: { $0.name < $1.name } ) }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
    
    func rates(for cryptoCurrencyIds: [String]) -> AnyPublisher<[String: Decimal], Never> {
        return provider
            .requestPublisher(TangemApiTarget(type: .rates(cryptoCurrencyIds: cryptoCurrencyIds, fiatCurrencyCode: selectedCurrencyCode), card: card))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RateInfoResponse.self)
            .map { $0.prices }
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
