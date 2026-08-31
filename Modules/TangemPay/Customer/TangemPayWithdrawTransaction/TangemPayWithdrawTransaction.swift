//
//  TangemPayWithdrawTransaction.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

public enum TangemPayWithdraw {
    public enum SignableData {
        struct Request: Encodable {
            let amountInCents: String
            let recipientAddress: String
            let chainId: Int?
            let tokenContractAddress: String?
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
            let chainId: Int?
            let tokenContractAddress: String?
        }

        struct Response: Decodable {
            let orderId: String
            let status: String
            let type: String
            let amountInCents: Decimal
        }
    }
}

// MARK: - Requests from the domain

extension TangemPayWithdraw.SignableData.Request {
    init(_ request: TangemPayWithdrawRequest) {
        self.init(
            amountInCents: request.amountInCents,
            recipientAddress: request.destination,
            chainId: request.target?.chainId,
            tokenContractAddress: request.target?.tokenContractAddress
        )
    }
}

extension TangemPayWithdraw.Transaction.Request {
    init(_ request: TangemPayWithdrawRequest, signature: TangemPayWithdrawSignature) {
        self.init(
            amountInCents: request.amountInCents,
            senderAddress: signature.sender,
            recipientAddress: request.destination,
            adminSignature: signature.signature.hexString.addHexPrefix(),
            adminSalt: signature.salt.hexString.addHexPrefix(),
            chainId: request.target?.chainId,
            tokenContractAddress: request.target?.tokenContractAddress
        )
    }
}
