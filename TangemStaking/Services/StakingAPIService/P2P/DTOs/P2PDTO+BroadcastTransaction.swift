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

        struct BroadcastTransactionInfo: Decodable {
            let hash: String
            let status: Status

            enum Status: String, Decodable {
                case success
                case failed
                case pending
            }
        }
    }
}
