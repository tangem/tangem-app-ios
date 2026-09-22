//
//  TangemPayWithdrawPreSignature.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct TangemPayWithdrawPreSignature {
    public let sender: String
    public let hash: Data
    public let salt: Data
    public let structuredData: EIP712TypedData

    public var isHashConsistent: Bool {
        structuredData.signHash == hash
    }

    public init(sender: String, hash: Data, salt: Data, structuredData: EIP712TypedData) {
        self.sender = sender
        self.hash = hash
        self.salt = salt
        self.structuredData = structuredData
    }
}

// MARK: - Order withdraw data

public extension TangemPayWithdrawPreSignature {
    init(_ withdrawData: TangemPayOrderResponse.Data.WithdrawData) {
        self.init(
            sender: withdrawData.senderAddress,
            hash: Data(hexString: withdrawData.hash),
            salt: Data(hexString: withdrawData.salt),
            structuredData: withdrawData.structuredData
        )
    }
}
