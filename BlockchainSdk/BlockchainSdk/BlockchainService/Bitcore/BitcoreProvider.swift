//
//  BitcoreProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import RxSwift
import Combine

class BitcoreProvider {
    let address: String
    let provider = MoyaProvider<BitcoreTarget>(plugins: [NetworkLoggerPlugin(verbose: true)])
    
    init(address: String) {
        self.address = address
    }
    
    func getBalance() -> Single<BitcoreBalance> {
        return provider
            .rx
            .request(.balance(address: address))
            .map(BitcoreBalance.self)
    }
    
    func getUnspents() -> Single<[BitcoreUtxo]> {
        return provider
            .rx
            .request(.unspents(address: address))
            .map([BitcoreUtxo].self)
    }
    
    @available(iOS 13.0, *)
    func send(_ transaction: String) -> AnyPublisher<BitcoreSendResponse, MoyaError> {
        return provider
            .requestPublisher(.balance(address: "asdasd"))
            .map(BitcoreSendResponse.self)
            .eraseToAnyPublisher()
    }
}



