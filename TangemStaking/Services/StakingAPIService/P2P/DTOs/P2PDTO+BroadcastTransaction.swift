//
//  P2PDTO+BroadcastTransaction.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    enum BroadcastTransaction {
        struct Request: Encodable {
            let signedTransaction: String
        }

        typealias Response = GenericResponse<BroadcastTransactionInfo>

        struct BroadcastTransactionInfo: Decodable {
            let hash: String
            let status: Status
            let blockNumber: Int
            let transactionIndex: Int
            let gasUsed: String
            let cumulativeGasUsed: String
            let effectiveGasPrice: String?
            let from: String
            let to: String

            enum Status: String, Decodable {
                case success
                case failed
            }
        }
    }
}
