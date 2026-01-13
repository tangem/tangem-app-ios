//
//  TangemPayWithdrawSignature.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayWithdrawSignature {
    public let sender: String
    public let signature: Data
    public let salt: Data

    public init(sender: String, signature: Data, salt: Data) {
        self.sender = sender
        self.signature = signature
        self.salt = salt
    }
}
