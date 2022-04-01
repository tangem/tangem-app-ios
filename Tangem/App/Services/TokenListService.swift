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
    
    func checkContractAddress(contractAddress: String, networkId: String?) -> AnyPublisher<CurrencyModel?, MoyaError> {
        provider
            .requestPublisher(.checkContractAddress(contractAddress: contractAddress, networkId: networkId))
            .filterSuccessfulStatusCodes()
            .map(CurrenciesList.self)
            .map { currencyList -> CurrencyModel? in
                guard
                    let currencyEntity = currencyList.tokens.first,
                    let currencyEntityIsActive = currencyEntity.active,
                    let contractIsActive = currencyEntity.contracts?.first?.active,
                    currencyEntityIsActive && contractIsActive
                else {
                    return nil
                }
                
                return CurrencyModel(with: currencyEntity, baseImageURL: currencyList.imageHost)
            }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
}
