//
//  TangemPayWithdrawPreSignature.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayWithdrawPreSignature {
    public let sender: String
    public let hash: Data
    public let salt: Data

    public init(sender: String, hash: Data, salt: Data) {
        self.sender = sender
        self.hash = hash
        self.salt = salt
    }
}
