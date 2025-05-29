//
//  WalletConnectDAppConnectionRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

struct WalletConnectDAppConnectionRequest {
    let proposalID: String
    let namespaces: [String: SessionNamespace]
}

extension WalletConnectDAppConnectionRequest {
    struct Account {
        let namespace: String
        let reference: String
        let address: String
    }

    struct SessionNamespace {
        let blockchains: Set<Blockchain>?
        let accounts: [Account]
        let methods: Set<String>
        let events: Set<String>
    }
}
