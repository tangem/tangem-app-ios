//
//  PolymarketWithdrawRecord.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketWithdrawRecord: Hashable, Sendable {
    public let transactionId: String
    public let state: PolymarketWithdrawState
    public let transactionHash: String?

    public init(transactionId: String, state: PolymarketWithdrawState, transactionHash: String?) {
        self.transactionId = transactionId
        self.state = state
        self.transactionHash = transactionHash
    }
}
