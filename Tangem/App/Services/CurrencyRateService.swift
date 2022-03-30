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


struct CurrencyCoinGeckoIdConverter {
    static func map(_ currencyCode: String) -> String {
        switch currencyCode {
        case "SOL": return "solana"
        case "BTC": return "bitcoin"
        case "ETH": return "ethereum"
        case "USDC": return "usd-coin"
        default: return ""
        }
    }
    
    static func map2(_ id: String) -> String {
        switch id {
        case "solana": return "SOL"
        case "bitcoin": return "BTC"
        case "ethereum": return "ETH"
        case "usd-coin": return "USDC"
        default: return ""
        }
    }
}

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
    
    func rates(for currencies: [String]) -> AnyPublisher<[String: Decimal], Never> {
        return provider
            .requestPublisher(.rates(cryptoCurrencyCodes: currencies, fiatCurrencyCode: selectedCurrencyCode))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RateInfoResponse.self)
            .map { $0.prices }
            .tryMap { dictionary in
                Dictionary(uniqueKeysWithValues: dictionary.map {
                    (CurrencyCoinGeckoIdConverter.map2($0.key), $0.value.rounded(scale: 2, roundingMode: .plain))
                })
            }
            .catch { _ in Empty(completeImmediately: true) }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
}
