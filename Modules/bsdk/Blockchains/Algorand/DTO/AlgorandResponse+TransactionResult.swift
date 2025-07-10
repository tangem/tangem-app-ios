//
//  AlgorandResponse+TransactionResult.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension AlgorandResponse {
    /// https://developer.algorand.org/docs/rest-apis/algod/#post-v2transactions
    struct TransactionResult: Decodable {
        let txId: String
    }
}
