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
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.walletConnectServiceProvider) private var walletConnectServiceProvider: WalletConnectServiceProviding

    private var bag = Set<AnyCancellable>()

    func initialize() {
        exchangeService.initialize()
        walletConnectServiceProvider.initialize()

        bind()
    }

    private func bind() {
        cardsRepository.didScanPublisher.sink { cardInfo in
            // subscrive to scan here
        }
        .store(in: &bag)
    }
}

protocol Initializable {
    func initialize()
}
