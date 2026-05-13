//
//  LitecoinNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class LitecoinNetworkService: MultiUTXONetworkProvider {
    override func getFee() -> AnyPublisher<UTXOFee, any Error> {
        super.getFee().map {
            UTXOFee(
                slowSatoshiPerByte: 1,
                marketSatoshiPerByte: $0.marketSatoshiPerByte,
                prioritySatoshiPerByte: $0.prioritySatoshiPerByte
            )
        }
        .eraseToAnyPublisher()
    }
}
