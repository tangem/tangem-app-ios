//
//  XPUBKeyGenerator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol XPUBKeyGenerator {
    func derivationIsNeeded() -> Bool
    func generateXPUBKey() async throws -> Wallet.PublicKey.XPUBKey
}
