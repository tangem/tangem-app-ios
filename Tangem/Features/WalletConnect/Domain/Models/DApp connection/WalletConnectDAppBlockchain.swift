//
//  WalletConnectDAppBlockchain.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

/// Represents a blockchain associated with a certain dApp.
struct WalletConnectDAppBlockchain: Hashable {
    /// Blockchain domain model.
    let blockchain: Blockchain

    /// Determines whether the blockchain is required by dApp.
    let isRequired: Bool
}
