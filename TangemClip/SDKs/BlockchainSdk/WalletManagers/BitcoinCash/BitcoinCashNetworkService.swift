//
//  BitcoinCashNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class BitcoinCashNetworkService {
    private let provider: BlockchairNetworkProvider

    init(provider: BlockchairNetworkProvider) {
        self.provider = provider
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return provider.getInfo(address: address)
    }
}
