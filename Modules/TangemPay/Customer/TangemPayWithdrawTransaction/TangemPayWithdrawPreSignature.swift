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

    public init(sender: String, hash: Data, salt: Data, structuredData: EIP712TypedData) {
        self.sender = sender
        self.hash = hash
        self.salt = salt
        self.structuredData = structuredData
    }
}
