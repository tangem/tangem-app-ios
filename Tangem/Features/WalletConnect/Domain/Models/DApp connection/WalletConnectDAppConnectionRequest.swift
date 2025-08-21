//
//  WalletConnectDAppConnectionRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct WalletConnectDAppConnectionRequest {
    let proposalID: String
    let namespaces: [String: WalletConnectSessionNamespace]
}
