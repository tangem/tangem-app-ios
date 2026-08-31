//
//  PolymarketDepositWalletState.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketDepositWalletState: Hashable, Sendable {
    public let depositWalletAddress: String?
    public let status: PolymarketDepositWalletStatus

    public init(depositWalletAddress: String?, status: PolymarketDepositWalletStatus) {
        self.depositWalletAddress = depositWalletAddress
        self.status = status
    }
}
