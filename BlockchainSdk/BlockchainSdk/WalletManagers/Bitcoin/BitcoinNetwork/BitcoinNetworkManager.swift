//
//  BitcoinNetwork.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk

class BitcoinNetworkManager {
    let providerRepo: BitcoinNetworkProviderRepository
    
    init(address: String, isTestNet:Bool) {
        var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
        providers[.blockcypher] = BlockcypherProvider(address: address, isTestNet: isTestNet)
        providers[.main] = BitcoinMainProvider(address: address)
        providerRepo = BitcoinNetworkProviderRepository(isTestNet: isTestNet, providers: providers)
    }
    
    
    
    //    func getInfo() -> AnyPublisher<BitcoinResponse, Error> {
    //
    //    }
}

struct BtcFee {
    let minimalKb: Decimal
    let normalKb: Decimal
    let priorityKb: Decimal
}

struct BitcoinResponse {
    let balance: Decimal
    let unconfirmed_balance: Int
    let txrefs: [BtcTx]
}

struct BtcTx {
    let tx_hash: String
    let tx_output_n: Int
    let value: UInt64
}

enum BitcoinNetworkApi {
    case main
    case blockcypher
}

protocol BitcoinNetworkProvider {
    //    func getFee()
    //    func getAddress()
    //    func send()
}

struct BitcoinNetworkProviderRepository {
    let isTestNet: Bool
    var networkApi: BitcoinNetworkApi = .main
    let providers:[BitcoinNetworkApi: BitcoinNetworkProvider]
    
    func getProvider() -> BitcoinNetworkProvider {
        if isTestNet {
            return providers[.blockcypher]!
        }
        
        return providers[networkApi]!
    }
}
