//
//  PolymarketBridgeService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketBridgeService {
    func supportedAssets() async throws -> [PolymarketSupportedAsset]

    func fundingAddresses(forDepositWallet depositWalletAddress: String) async throws -> PolymarketBridgeFundingAddresses
}
