//
//  WalletConnectSessionProposal.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

struct WalletConnectSessionProposal {
    let requiredBlockchains: Set<Blockchain>
    let optionalBlockchains: Set<Blockchain>

    let dAppConnectionRequestFactory: (
        _ selectedBlockchains: Set<Blockchain>,
        _ selectedUserWallet: any UserWalletModel
    ) throws -> WalletConnectDAppConnectionRequest
}
