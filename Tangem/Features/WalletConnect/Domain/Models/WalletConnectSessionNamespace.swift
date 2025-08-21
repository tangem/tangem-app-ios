//
//  WalletConnectSessionNamespace.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

struct WalletConnectSessionNamespace: Hashable {
    let blockchains: Set<Blockchain>?
    let accounts: [WalletConnectAccount]
    let methods: Set<String>
    let events: Set<String>
}
