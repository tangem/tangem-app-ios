//
//  LitecoinNetworkManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class LitecoinNetworkManager: BitcoinNetworkProvider {
    
    let provider: BitcoinNetworkProvider
    
    init(address: String) {
        provider = BlockcypherProvider(address: address, coin: .ltc, chain: .main)
    }
    
    func getInfo() -> Single<BitcoinResponse> {
        return provider.getInfo()
    }
    
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return Just
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        <#code#>
    }
    
    
}
