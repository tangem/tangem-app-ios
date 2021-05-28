//
//  EthereumJsonRpcProvider.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class EthereumJsonRpcProvider {
    
    private let provider: MoyaProvider<EthereumTarget> = .init(
        plugins: [NetworkLoggerPlugin()]
    )
    private let network: EthereumNetwork
    
    init(network: EthereumNetwork) {
        self.network = network
    }
    
    func getBalance(for address: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .balance(address: address, network: network))
    }
    
    func getTokenBalance(for address: String, contractAddress: String) -> AnyPublisher<EthereumResponse, Error> {
        requestPublisher(for: .tokenBalance(address: address, contractAddress: contractAddress, network: network))
    }
    
    private func requestPublisher(for target: EthereumTarget) -> AnyPublisher<EthereumResponse, Error> {
        provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(EthereumResponse.self)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
