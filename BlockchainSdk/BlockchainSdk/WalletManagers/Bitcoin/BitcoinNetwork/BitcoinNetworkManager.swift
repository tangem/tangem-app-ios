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
import RxSwift
import Alamofire

class BitcoinNetworkManager: BitcoinNetworkProvider {
    let isTestNet: Bool
    var networkApi: BitcoinNetworkApi = .main
    let providers: [BitcoinNetworkApi: BitcoinNetworkProvider]
    
    init(providers:[BitcoinNetworkApi: BitcoinNetworkProvider], isTestNet:Bool) {
        self.providers = providers
        self.isTestNet = isTestNet
    }
    
    convenience init(address: String, isTestNet:Bool) {
        var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
        providers[.blockcypher] = BlockcypherProvider(address: address, coin: .btc, chain:  isTestNet ? .test3: .main)
        providers[.main] = BitcoinMainProvider(address: address)
        self.init(providers:providers, isTestNet: isTestNet)
    }
    
    func getInfo() -> Single<BitcoinResponse> {
        return getProvider()
            .flatMap { $0.getInfo() }
            .catchError {[unowned self] error in
                if let moyaError = error as? MoyaError,
                    case let MoyaError.statusCode(response) = moyaError,
                    self.providers.count > 1,
                    response.statusCode > 299  {
                    if self.networkApi == .main {
                        self.networkApi = .blockcypher
                    }
                }
                
                throw error
        }
        .retry(1)
    }
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return getProviderCombine()
            .setFailureType(to: Error.self)
            .flatMap{ $0.getFee() }
            .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return getProviderCombine()
            .setFailureType(to: Error.self)
            .flatMap{ $0.send(transaction: transaction) }
            .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    private func getProviderCombine() -> Just<BitcoinNetworkProvider> {
        return isTestNet ? Just(providers[.blockcypher]!) : Just(providers[networkApi]!)
    }
    
    func getProvider() -> Single<BitcoinNetworkProvider> {
        return isTestNet ? Observable.just(providers[.blockcypher]!).asSingle()
        : Observable.just(providers[networkApi]!).asSingle()
    }
}

struct BtcFee {
    let minimalKb: Decimal
    let normalKb: Decimal
    let priorityKb: Decimal
}

struct BitcoinResponse {
    let balance: Decimal
    let hasUnconfirmed: Bool
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
    func getInfo() -> Single<BitcoinResponse>
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error>
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error>
}
