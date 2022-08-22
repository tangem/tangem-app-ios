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
    @Injected(\.supportChatService) private var supportChatService: SupportChatServiceProtocol
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var bag = Set<AnyCancellable>()

    func initialize() {
        exchangeService.initialize()
        walletConnectServiceProvider.initialize()
        supportChatService.initialize()
        tangemApiService.initialize()

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
