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
    
    func checkContractAddress(contractAddress: String, networkId: String?) -> AnyPublisher<[CurrencyModel], MoyaError> {
        provider
            .requestPublisher(.checkContractAddress(contractAddress: contractAddress, networkId: networkId))
            .filterSuccessfulStatusCodes()
            .map(CurrenciesList.self)
            .map { currencyList -> [CurrencyModel] in
                return currencyList
                    .tokens
                    .filter {
                        $0.active == true
                    }
                    .compactMap { currencyEntity in
                        let activeContracts = currencyEntity.contracts?.filter {
                            $0.active == true && $0.address == contractAddress
                        }
                        
                        guard activeContracts?.isEmpty == false else {
                            return nil
                        }
                        
                        let filteredCurrencyEntity = CurrencyEntity(
                            id: currencyEntity.id,
                            name: currencyEntity.name,
                            symbol: currencyEntity.symbol,
                            active: currencyEntity.active,
                            contracts: activeContracts
                        )
                        
                        return CurrencyModel(with: filteredCurrencyEntity, baseImageURL: currencyList.imageHost)
                    }
            }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
}
