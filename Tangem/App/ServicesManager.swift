//
//  ServicesManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ServicesManager {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.geoIpService) private var geoIpService: GeoIpService
    
    private var bag = Set<AnyCancellable>()
    
    func initialize() {
        exchangeService.initialize()
        geoIpService.initialize()
        
        bind()
    }
    
    private func bind() {
        cardsRepository.didScanPublisher.sink {cardInfo in
         //subscrive to scan here
        }
        .store(in: &bag)
    }
}

protocol Initializable {
    func initialize()
}
