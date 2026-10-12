//
//  PolymarketDepositWallet.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketDepositWallet: Hashable, Sendable {
    public let address: String?
    public let status: PolymarketDepositWalletStatus

    public init(address: String?, status: PolymarketDepositWalletStatus) {
        self.address = address
        self.status = status
    }
}
