//
//  CollectiblesVaultUsdcAccount.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct CollectiblesVaultUsdcAccount: Hashable, Sendable {
    public let address: String
    public let mint: String

    public init(address: String, mint: String) {
        self.address = address
        self.mint = mint
    }
}
