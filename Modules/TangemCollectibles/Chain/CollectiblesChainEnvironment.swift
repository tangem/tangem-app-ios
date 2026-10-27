//
//  CollectiblesChainEnvironment.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
public import BlockchainSdk

// [REDACTED_TODO_COMMENT]
/// Chain coordinates of the collectibles vault program. The program id and the cluster move together,
/// never separately — a devnet id read against mainnet answers "no vault" for every wallet.
public enum CollectiblesChainEnvironment {
    public static let programId = CollectiblesVaultProgram.devnetProgramId

    /// The RPC cluster only; key derivation pins its own blockchain in `CollectiblesAccountKeyPath`.
    public static var blockchain: Blockchain { .solana(curve: .ed25519, testnet: true) }

    // [REDACTED_TODO_COMMENT]
    /// Spending caps in base USDC units (6 decimals) a fresh vault is initialized with.
    public static let initialPerSpinCap: UInt64 = 50_000_000_000
    public static let initialDailyCap: UInt64 = 500_000_000_000
}
