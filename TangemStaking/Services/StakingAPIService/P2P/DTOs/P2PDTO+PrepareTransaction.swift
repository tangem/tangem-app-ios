//
//  P2PDTO+PrepareTransaction.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    enum PrepareTransaction {
        struct Request: Encodable {
            let delegatorAddress: String
            let vaultAddress: String
            let amount: Decimal
        }

        struct PrepareTransactionInfo: Decodable {
            let amount: Decimal
            let vaultAddress: String
            let delegatorAddress: String
            let unsignedTransaction: UnsignedTransaction
            let createdAt: Date
        }
    }
}
