//
//  MainQRPaymentRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct MainQRPaymentRequest: Equatable {
    let blockchain: Blockchain
    let destinationAddress: String
    let amount: Decimal?
    let rawAmount: String?
    let memo: String?
    let tokenContractAddress: String?
}

struct MainQRResolvedPaymentRequest: Equatable {
    let request: MainQRPaymentRequest
    let matchingTokenItems: [TokenItem]

    var matchCount: Int {
        matchingTokenItems.count
    }
}

struct MainQRAddressRequest: Equatable {
    let destinationAddress: String
    let matchingBlockchains: [Blockchain]
    let matchCount: Int
}
