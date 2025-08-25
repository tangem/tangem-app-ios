//
//  WalletConnectDAppSession.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date

struct WalletConnectDAppSession: Hashable {
    let topic: String
    let namespaces: [String: WalletConnectSessionNamespace]
    let expiryDate: Date
}
