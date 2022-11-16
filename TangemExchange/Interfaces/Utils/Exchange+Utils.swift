//
//  Exchange+Utils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import ExchangeSdk
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
extension ExchangeBlockchain: CaseIterable {
    public static var allCases: [ExchangeBlockchain] {
    [
        .ethereum,
        .bsc,
        .polygon,
        .optimism,
        .arbitrum,
        .gnosis,
        .avalanche,
        .fantom,
        .klayth,
        .aurora
    ]
    }
}

extension ExchangeBlockchain {
    static func exchangeBlockchain(from chainId: Int?) -> ExchangeBlockchain {
        return .gnosis
        // [REDACTED_TODO_COMMENT]
//        
//        guard let chainId = chainId,
//              let blockchain = ExchangeBlockchain.allCases.first(where: { $0.id == String(chainId) }) else {
//            fatalError("OneInch not support this blockchain")
//        }
//        
//        return blockchain
    }
}
