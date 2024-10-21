//
//  AlgorandRequest+Transaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension AlgorandRequest {
    /// https://developer.algorand.org/docs/rest-apis/algod/#get-v2transactionsparams
    struct TransactionParams: Decodable {
        let genesisId: String
        let genesisHash: String
        let fee: UInt64
        let lastRound: UInt64
        let nonce: String?
    }
}
