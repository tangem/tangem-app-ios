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

struct FiatResponse: Codable {
    let currencies: [FiatCurrency]
}

struct FiatCurrency: Codable, Identifiable, CustomStringConvertible {
    let id: String
    let name: String
    let unit: String
    
    var symbol: String {
        id.uppercased()
    }
    
    var description: String {
        let localizedName = Locale.current.localizedString(forCurrencyCode: symbol)?.capitalizingFirstLetter() ?? name
        return "\(localizedName) (\(symbol)) - \(unit)"
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
    
    let provider = MoyaProvider<TangemApiTarget>()
    
    internal init() {
        
    }
    
    deinit {
        print("CurrencyRateService deinit")
    }
    
    func baseCurrencies() -> AnyPublisher<[FiatCurrency], MoyaError> {
        provider
            .requestPublisher(.baseCurrencies)
            .filterSuccessfulStatusCodes()
            .map(FiatResponse.self)
            .map { $0.currencies.sorted(by: { $0.name < $1.name } ) }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
    
    func rates(for cryptoCurrencyIds: [String]) -> AnyPublisher<[String: Decimal], Never> {
        return provider
            .requestPublisher(.rates(cryptoCurrencyIds: cryptoCurrencyIds, fiatCurrencyCode: selectedCurrencyCode))
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
