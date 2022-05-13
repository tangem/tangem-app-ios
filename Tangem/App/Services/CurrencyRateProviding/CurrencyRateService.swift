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
    @Injected(\.cardsRepository) var cardsRepository: CardsRepository {
        didSet {
            cardsRepository.didScanPublisher.sink {[weak self] cardInfo in
                self?.card = cardInfo.card
            }
            .store(in: &bag)
        }
    }
    
    @Storage(type: StorageType.selectedCurrencyCode, defaultValue: "USD")
    
    var selectedCurrencyCode: String {
        didSet {
            selectedCurrencyCodePublished = selectedCurrencyCode
        }
    }
    
    @Published var selectedCurrencyCodePublished: String = ""
    
    private var card: Card?
    
    private let provider = MoyaProvider<TangemApiTarget>()
    private var bag: Set<AnyCancellable> = .init()
    
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
