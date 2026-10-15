//
//  MCPConnectionRequestUserWalletSelectorState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.UserWalletId

// [REDACTED_TODO_COMMENT]
struct MCPConnectionRequestUserWalletSelectorState: Equatable {
    let navigationTitle = "Choose wallet"
    let userWallets: [MCPUserWallet]
    var selectedUserWalletID: MCPUserWallet.ID?
}
