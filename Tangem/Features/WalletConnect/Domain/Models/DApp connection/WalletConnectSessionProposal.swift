//
//  WalletConnectSessionProposal.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

struct WalletConnectSessionProposal {
    let id: String
    let requiredBlockchains: Set<Blockchain>
    let optionalBlockchains: Set<Blockchain>

    let dAppConnectionRequestFactory: (
        _ selectedBlockchains: any Sequence<Blockchain>,
        _ selectedUserWallet: any UserWalletModel
    ) throws(WalletConnectDAppProposalApprovalError) -> WalletConnectDAppConnectionRequest
}
