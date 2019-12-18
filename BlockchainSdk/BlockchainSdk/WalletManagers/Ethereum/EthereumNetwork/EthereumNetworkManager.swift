//
//  EthereumNetworkManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import SwiftyJSON

class EthereumNetworkManager {
    let provider = MoyaProvider<EthereumTarget>()
    
    func getBalance(address: String) -> AnyPublisher<Decimal, Error> {
        let future = Future<Decimal, Error>() {[unowned self] promise in
            self.provider.request(.balance(address: address)) { result in
                switch result {
                case .success(let response):
                    let balanceInfo = JSON(response.data)
                    
                    guard balanceInfo["result"] != JSON.null else {
                            promise(.failure("ETH Main – Missing check string"))
                        return
                    }
                    
                    let quantity = balanceInfo["result"].stringValue
                    let balanceData = Data(hex: quantity)
                    guard let balanceWei = Decimal(data: balanceData) else {
                         promise(.failure("Failed to convert the quantity"))
                        return
                    }
                    
                    let balanceEth = balanceWei / Decimal(1000000000000000000)
                    promise(.success(balanceEth))
                
                case .failure(let moyaError):
                    promise(.failure(moyaError))
                }
            }
        }
        return future.eraseToAnyPublisher()
    }
}


struct EthereumResponse {
    
}
