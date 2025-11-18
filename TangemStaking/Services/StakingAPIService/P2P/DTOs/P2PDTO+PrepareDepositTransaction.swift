//
//  P2PDTO+PrepareDepositTransaction.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    enum PrepareDepositTransaction {
        struct Request: Encodable {
            let delegatorAddress: String
            let vaultAddress: String
            let amount: Double
        }

        typealias Response = GenericResponse<PrepareDepositTransactionInfo>

        struct PrepareDepositTransactionInfo: Decodable {
            let amount: Double
            let vaultAddress: String
            let delegatorAddress: String
            let unsignedTransaction: UnsignedTransaction
            let createdAt: Date
        }

        struct UnsignedTransaction: Decodable {
            let serializeTx: String
            let to: String
            let data: String
            let value: String
            let nonce: Int
            let chainId: Int
            let gasLimit: String
            let maxFeePerGas: String
            let maxPriorityFeePerGas: String
        }
    }
}
