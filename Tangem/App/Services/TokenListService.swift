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

class TokenListService {
    let provider = MoyaProvider<TangemApiTarget2>()
    
    init() {
        
    }
    
    deinit {
        print("TokenListService deinit")
    }
    
    func checkContractAddress(contractAddress: String, networkId: String) -> AnyPublisher<TokenItem?, MoyaError> {
        provider
            .requestPublisher(.checkContractAddress(contractAddress: contractAddress, networkId: networkId))
            .filterSuccessfulStatusCodes()
            .map(CurrenciesList.self)
            .map { currencyList -> TokenItem? in
                guard
                    let currencyEntity = currencyList.tokens.first,
                    let active = currencyEntity.contracts?.first?.active,
                    active == true
                else {
                    return nil
                }
                
                let currencyModel = CurrencyModel(with: currencyEntity, baseImageURL: currencyList.imageHost)
                return currencyModel.items.first
            }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
}
