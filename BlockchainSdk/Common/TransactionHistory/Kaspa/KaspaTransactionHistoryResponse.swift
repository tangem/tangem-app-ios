//
//  KaspaTransactionHistoryResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// just namespace to avoid conflict with BlockchainSdk -> KaspaTransaction
enum KaspaTransactionHistoryResponse {
    struct Transaction: Decodable {
        let transactionId: String
        let hash: String
        let blockTime: Date
        let isAccepted: Bool
        let inputs: [Input]
        let outputs: [Output]

        struct Input: Decodable {
            let previousOutpointAddress: String
            let previousOutpointAmount: Int
        }

        struct Output: Decodable {
            let amount: Int
            let scriptPublicKeyAddress: String
        }
    }
}
