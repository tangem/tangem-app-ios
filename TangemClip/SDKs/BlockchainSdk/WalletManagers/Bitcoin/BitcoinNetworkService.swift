//
//  BitcoinNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import Alamofire

class BitcoinNetworkService: MultiNetworkProvider<BitcoinNetworkProvider>, BitcoinNetworkProvider {
    
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        providerPublisher {
            $0.getInfo(addresses: addresses)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        providerPublisher{
            $0.getInfo(address: address)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
}
