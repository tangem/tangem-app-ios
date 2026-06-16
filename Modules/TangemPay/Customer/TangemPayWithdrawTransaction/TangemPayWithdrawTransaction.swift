//
//  TangemPayWithdrawTransaction.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public enum TangemPayWithdraw {
    public enum SignableData {
        struct Request: Encodable {
            let amountInCents: String
            let recipientAddress: String
        }

        struct Response: Decodable {
            let hash: String
            let salt: String
            let senderAddress: String
            let structuredData: EIP712TypedData
        }
    }

    public enum Transaction {
        struct Request: Encodable {
            let amountInCents: String
            let senderAddress: String
            let recipientAddress: String
            let adminSignature: String
            let adminSalt: String
        }

        struct Response: Decodable {
            let orderId: String
            let status: String
            let type: String
            let amountInCents: Decimal
        }
    }
}
