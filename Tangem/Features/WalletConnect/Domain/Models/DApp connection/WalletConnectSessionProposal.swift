//
//  WalletConnectSessionProposal.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

struct WalletConnectSessionProposal {
    struct Account {
        let namespace: String
        let reference: String
        let address: String
    }

    struct Namespace {
        let blockchains: Set<Blockchain>?
        let accounts: [Account]?
        let methods: Set<String>
        let events: Set<String>
    }

    let id: String
    let requiredNamespaces: [String: Namespace]
    let optionalNamespaces: [String: Namespace]?

    // [REDACTED_TODO_COMMENT]
    let unsupportedBlockchainNames: Set<String>

    let dAppConnectionRequestFactory: (
        _ selectedBlockchains: [BlockchainSdk.Blockchain],
        _ selectedUserWallet: any UserWalletModel
    ) throws -> WalletConnectDAppConnectionRequest
}
