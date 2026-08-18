//
//  PolymarketWalletState.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketWalletState: Hashable, Sendable {
    public let depositWalletAddress: String?
    public let status: PolymarketWalletStatus

    public init(depositWalletAddress: String?, status: PolymarketWalletStatus) {
        self.depositWalletAddress = depositWalletAddress
        self.status = status
    }
}
