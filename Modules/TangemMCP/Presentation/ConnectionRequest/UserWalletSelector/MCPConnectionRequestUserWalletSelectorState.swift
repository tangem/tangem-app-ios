//
//  MCPConnectionRequestUserWalletSelectorState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class UIKit.UIImage
import struct TangemFoundation.UserWalletId

// [REDACTED_TODO_COMMENT]
struct MCPConnectionRequestUserWalletSelectorState: Equatable {
    let navigationTitle = "Choose wallet"
    let userWallets: [MCPConnectionRequestUserWalletSelectorRowViewModel]
}
