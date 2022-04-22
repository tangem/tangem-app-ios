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

class CoinsService {
    let provider = MoyaProvider<TangemApiTarget>()
    
    var card: Card?
    
    init() {}
    
    deinit {
        print("CoinsService deinit")
    }
    
    func checkContractAddress(contractAddress: String, networkId: String?) -> AnyPublisher<[CoinModel], MoyaError> {
        provider
            .requestPublisher(TangemApiTarget(type: .coins(contractAddress: contractAddress, networkId: networkId), card: card))
            .filterSuccessfulStatusCodes()
            .map(CoinsResponse.self)
            .map {[weak self] list -> [CoinModel] in
                guard let self = self else { return [] }
                
                return list.coins
                    .compactMap {
                        let model = CoinModel(with: $0, baseImageURL: list.imageHost)
                        
                        if let card = self.card {
                            return model.makeFiltered(with: card)
                        }
                        
                        return model
                    }

            }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
}
