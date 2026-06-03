//
//  HederaNetworkResult.ContractCall.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    struct ContractInfo: Decodable {
        /// Network entity ID in the format of `shard.realm.num`.
        let contractId: String?
    }

    struct ContractCallResult: Decodable {
        let result: String?
    }

    struct NetworkFees: Decodable {
        struct Fee: Decodable {
            let transactionType: String
            let gas: Int?
        }

        let fees: [Fee]
    }
}
