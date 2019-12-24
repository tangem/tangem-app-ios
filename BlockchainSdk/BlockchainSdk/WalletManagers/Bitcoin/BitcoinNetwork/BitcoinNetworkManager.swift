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
    let isTestNet: Bool
    var networkApi: BitcoinNetworkApi = .main
    let providers:[BitcoinNetworkApi: BitcoinNetworkProvider]
    
    init(address: String, isTestNet:Bool) {
        var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
        providers[.blockcypher] = BlockcypherProvider(address: address, isTestNet: isTestNet)
        providers[.main] = BitcoinMainProvider(address: address)
        self.isTestNet = isTestNet
        self.providers = providers
    }
    
    func getInfo() -> AnyPublisher<BitcoinResponse, Error> {
        return getProvider()
            .setFailureType(to: Error.self)
            .flatMap{ $0.getInfo() }
            .tryCatch {[unowned self] error throws -> AnyPublisher<BitcoinResponse, Error> in
                if let moyaError = error as? MoyaError {
                    //[REDACTED_TODO_COMMENT]
                    if self.networkApi == .main {
                        self.networkApi = .blockcypher
                    }
                }
                
                throw error
        }
        .retry(1)
        .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return getProvider()
            .setFailureType(to: Error.self)
            .flatMap{ $0.getFee() }
            .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return getProvider()
            .setFailureType(to: Error.self)
            .flatMap{ $0.send(transaction: transaction) }
            .eraseToAnyPublisher()
    }
    
    private func getProvider() -> Just<BitcoinNetworkProvider> {
        if isTestNet {
            return Just(providers[.blockcypher]!)
        }
        
        return Just(providers[networkApi]!)
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
