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
import TangemSdk

class BitcoinCashNetworkService: BitcoinNetworkService {
    override func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        super.getInfo(address: addresses[0].removeBchPrefix())
            .map { [$0] }
            .eraseToAnyPublisher()
    }
    override func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        super.getInfo(address: address.removeBchPrefix())
    }
	
    override func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
		super.getSignatureCount(address: address.removeBchPrefix()) //[REDACTED_TODO_COMMENT]
	}
}
