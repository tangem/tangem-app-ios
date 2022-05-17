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

class CommonCoinsService: CoinsService {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    
    private let provider = MoyaProvider<TangemApiTarget>()
    private var bag: Set<AnyCancellable> = .init()
    
    init() {}
    
    deinit {
        print("CoinsService deinit")
    }
    
    func checkContractAddress(contractAddress: String, networkId: String?) -> AnyPublisher<[CoinModel], Never> {
        guard let card = cardsRepository.lastScanResult.card else {
            return Just([]).eraseToAnyPublisher()
        }
        
        return provider
            .requestPublisher(TangemApiTarget(type: .coins(contractAddress: contractAddress, networkId: networkId), card: card))
            .filterSuccessfulStatusCodes()
            .map(CoinsResponse.self)
            .map {list -> [CoinModel] in
                return list.coins
                    .compactMap {
                        let model = CoinModel(with: $0, baseImageURL: list.imageHost)
                        return model.makeFiltered(with: card, contractAddress: contractAddress)
                    }
            }
            .subscribe(on: DispatchQueue.global())
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
}
