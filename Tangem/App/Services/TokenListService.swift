//
//  TokenListService.swift
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

class TokenListService {
    let provider = MoyaProvider<TangemApiTarget>()
    
    var card: Card?
    
    init() {
        
    }
    
    deinit {
        print("TokenListService deinit")
    }
    
    func checkContractAddress(contractAddress: String, networkId: String?) -> AnyPublisher<[CoinModel], MoyaError> {
        Just([]).setFailureType(to: MoyaError.self)
            .eraseToAnyPublisher()
//        provider
//            .requestPublisher(TangemApiTarget(type: .checkContractAddress(contractAddress: contractAddress, networkId: networkId), card: card))
//            .filterSuccessfulStatusCodes()
//            .map(CoinsResponse.self)
//            .map { coinsList -> [CoinModel] in
//                return coinsList
//                    .coins
//                    .filter { $0.active }
//                    .compactMap { coin in
//                        let activeContracts = coin.networks.filter {
//                            if let blockchain = Blockchain(from: $0.networkId),
//                               case .solana = blockchain,
//                               let card = self.card,
//                               !card.canSupportSolanaTokens {
//                                return false
//                            }
//
//                            return $0.active == true && $0.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
//                        }
//
//                        guard !activeContracts.isEmpty else {
//                            return nil
//                        }
//
//                        let filtered = coin.makeCopy(with: activeContracts)
//
//                        return CoinModel(with: filtered, baseImageURL: coinsList.imageHost)
//                    }
//            }
//            .subscribe(on: DispatchQueue.global())
//            .eraseToAnyPublisher()
    }
}
