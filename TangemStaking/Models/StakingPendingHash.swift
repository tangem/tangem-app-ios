//
//  StakingPendingHash.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingPendingHash {
    public let transactionId: String
    public let hash: String

    public init(transactionId: String, hash: String) {
        self.transactionId = transactionId
        self.hash = hash
    }
}
