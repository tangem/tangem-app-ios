//
//  BitcoreProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class BitcoreProvider {
    let provider = MoyaProvider<BitcoreTarget>(plugins: [NetworkLoggerPlugin()])
    
    func getBalance(address: String) -> AnyPublisher<BitcoreBalance, MoyaError> {
        return provider
            .requestPublisher(.balance(address: address))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BitcoreBalance.self)
            .eraseToAnyPublisher()
    }
    
    func getUnspents(address: String) -> AnyPublisher<[BitcoreUtxo], MoyaError> {
        return provider
            .requestPublisher(.unspents(address: address))
            .filterSuccessfulStatusAndRedirectCodes()
            .map([BitcoreUtxo].self)
            .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(_ transaction: String) -> AnyPublisher<BitcoreSendResponse, MoyaError> {
        return provider
            .requestPublisher(.send(txHex: transaction))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BitcoreSendResponse.self)
            .eraseToAnyPublisher()
    }
}



