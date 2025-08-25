//
//  WalletConnectDAppData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL

struct WalletConnectDAppData: Hashable {
    let name: String
    let domain: URL
    let icon: URL?
}
