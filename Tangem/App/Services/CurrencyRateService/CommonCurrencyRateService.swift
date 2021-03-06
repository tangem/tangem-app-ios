//
//  CommonCurrencyRateService.swift
//  Tangem
//
//  Created by Alexander Osokin on 01.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk

class CommonCurrencyRateService: CurrencyRateService {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    
    @Storage(type: StorageType.selectedCurrencyCode, defaultValue: "USD")
    
    var selectedCurrencyCode: String {
        didSet {
            selectedCode = selectedCurrencyCode
        }
    }
       
    var selectedCurrencyCodePublisher: Published<String>.Publisher { $selectedCode }
    
    @Published private var selectedCode: String = ""
    private let provider = MoyaProvider<TangemApiTarget>()
    private var bag: Set<AnyCancellable> = .init()
    
    internal init() {}
    
    deinit {
        print("CurrencyRateService deinit")
    }
    
    func baseCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error> {
        guard let card = cardsRepository.lastScanResult.card else {
            return Fail(error: CardsRepositoryError.noCard).eraseToAnyPublisher()
        }
        
        return provider
            .requestPublisher(TangemApiTarget(type: .currencies, card: card))
            .filterSuccessfulStatusCodes()
            .map(CurrenciesResponse.self)
            .map { $0.currencies.sorted(by: { $0.name < $1.name } ) }
            .subscribe(on: DispatchQueue.global())
            .mapError { _ in AppError.serverUnavailable }
            .eraseToAnyPublisher()
    }
    
    func rates(for coinIds: [String]) -> AnyPublisher<[String: Decimal], Never> {
        guard let card = cardsRepository.lastScanResult.card else {
            return Just([:]).eraseToAnyPublisher()
        }
        
        return provider
            .requestPublisher(TangemApiTarget(type: .rates(coinIds: coinIds, currencyId: selectedCurrencyCode), card: card))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RatesResponse.self)
            .map { $0.rates }
            .catch { _ in Empty(completeImmediately: true) }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
}
