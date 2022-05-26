//
//  CoinsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import BlockchainSdk
import TangemSdk

class CommonCoinsService {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    
    private let provider = MoyaProvider<TangemApiTarget>()
    private var bag: Set<AnyCancellable> = .init()
    
    init() {}
    
    deinit {
        print("CoinsService deinit")
    }
}

// MARK: - CoinsService

extension CommonCoinsService: CoinsService {
    func loadCoins(requestModel: CoinsListRequestModel) -> AnyPublisher<[CoinModel], Error> {
        let card = cardsRepository.lastScanResult.card
        let target = TangemApiTarget(type: .coins(requestModel), card: card)
        
        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(CoinsResponse.self)
            .eraseError()
            .receive(on: DispatchQueue.global())
            .map { list -> [CoinModel] in
                list.coins.map { CoinModel(with: $0, baseImageURL: list.imageHost) }
            }
            .eraseToAnyPublisher()
    }
}
