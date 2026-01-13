//
//  TangemPayWithdrawTransaction.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemPayWithdraw {
    public enum SignableData {
        public struct Request: Encodable {
            let amountInCents: String
            let recipientAddress: String
        }

        public struct Response: Decodable {
            // If needed to work with this EIP712 format
            // We have to move `EIP712TypedData` to `TangemFoundation` or `BSDK` layer
            // let structuredData: EIP712TypedData?
            let hash: String
            let salt: String
            let senderAddress: String
        }
    }

    public enum Transaction {
        public struct Request: Encodable {
            let amountInCents: String
            let senderAddress: String
            let recipientAddress: String
            let adminSignature: String
            let adminSalt: String
        }

        public struct Response: Decodable {
            let orderId: String
            let status: String
            let type: String
            let amountInCents: Decimal
        }
    }
}
