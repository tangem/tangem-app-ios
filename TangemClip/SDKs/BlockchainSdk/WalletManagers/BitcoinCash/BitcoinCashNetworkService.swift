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
import TangemSdkClips

class BitcoinCashNetworkService {
    private let provider: BlockchairNetworkProvider

    init(provider: BlockchairNetworkProvider) {
        self.provider = provider
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return provider.getInfo(address: address)
    }
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return provider.getFee()
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.send(transaction: transaction)
    }
	
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
		provider.getSignatureCount(address: address)
	}
}
