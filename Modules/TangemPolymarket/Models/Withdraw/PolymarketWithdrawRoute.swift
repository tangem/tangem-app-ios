//
//  PolymarketWithdrawRoute.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketWithdrawRoute: Hashable, Sendable {
    public let destinationChainId: String
    public let destinationTokenAddress: String
    public let recipientAddress: String

    public init(destinationChainId: String, destinationTokenAddress: String, recipientAddress: String) {
        self.destinationChainId = destinationChainId
        self.destinationTokenAddress = destinationTokenAddress
        self.recipientAddress = recipientAddress
    }
}
