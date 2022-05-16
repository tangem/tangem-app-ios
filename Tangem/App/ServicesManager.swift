//
//  ServicesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ServicesManager {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    
    @Injected(\.appFeaturesService) private var appFeaturesService: AppFeaturesProviding
    @Injected(\.coinsService) private var coinsService: CoinsService
    @Injected(\.currencyRateService) private var currencyRateService: CurrencyRateService
    
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    
    private var bag = Set<AnyCancellable>()
    
    func initialize() {
        exchangeService.initialize()
        
        bind()
    }
    
    private func bind() {
        cardsRepository.didScanPublisher.sink {[weak self] cardInfo in
         //subscrive to scan here
        }
        .store(in: &bag)
    }
}

protocol Initializable {
    func initialize()
}
