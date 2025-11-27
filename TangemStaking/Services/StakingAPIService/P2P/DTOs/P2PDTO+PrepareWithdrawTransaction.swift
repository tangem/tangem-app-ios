//
//  P2PDTO+PrepareWithdrawTransaction.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    enum PrepareWithdrawTransaction {
        struct Request: Encodable {
            let stakerAddress: String
        }

        typealias Response = GenericResponse<PrepareWithdrawTransactionInfo>

        struct PrepareWithdrawTransactionInfo: Decodable {
            let amount: Decimal
            let vaultAddress: String
            let delegatorAddress: String
            let unsignedTransaction: UnsignedTransaction
            let createdAt: Date
            let tickets: [String]
        }
    }
}
