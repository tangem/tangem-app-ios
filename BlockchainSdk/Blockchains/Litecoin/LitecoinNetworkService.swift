//
//  LitecoinNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class LitecoinNetworkService: BitcoinNetworkService {
    override func getFee() -> AnyPublisher<BitcoinFee, Error> {
        providerPublisher { provider in
            provider.getFee()
                .retry(2)
                .map { BitcoinFee(minimalSatoshiPerByte: 1, normalSatoshiPerByte: $0.normalSatoshiPerByte, prioritySatoshiPerByte: $0.prioritySatoshiPerByte) }
                .eraseToAnyPublisher()
        }
    }
}
