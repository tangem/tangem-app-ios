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

class BitcoinNetworkManager: BitcoinNetworkProvider {
    let providerRepo: BitcoinNetworkProviderRepository
    
    init(address: String, isTestNet:Bool) {
        var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
        providers[.blockcypher] = BlockcypherProvider(address: address, isTestNet: isTestNet)
        providers[.main] = BitcoinMainProvider(address: address)
        providerRepo = BitcoinNetworkProviderRepository(isTestNet: isTestNet, providers: providers)
    }
    
    func getInfo() -> AnyPublisher<BitcoinResponse, Error> {
        return providerRepo.getProvider().getInfo()
    }
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return providerRepo.getProvider().getFee()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return providerRepo.getProvider().send(transaction: transaction)
    }
}

struct BtcFee {
    let minimalKb: Decimal
    let normalKb: Decimal
    let priorityKb: Decimal
}

struct BitcoinResponse {
    let balance: Decimal
    let hacUnconfirmed: Bool
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
    func getInfo() -> AnyPublisher<BitcoinResponse, Error>
    func getFee() -> AnyPublisher<BtcFee, Error>
    func send(transaction: String) -> AnyPublisher<String, Error>
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
