//
//  MCPConnectionRequestUserWalletSelectorState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.UserWalletId
import enum TangemLocalization.Localization

struct MCPConnectionRequestUserWalletSelectorState: Equatable {
    let navigationTitle = Localization.commonChooseWallet
    let userWallets: [MCPConnectionRequestUserWalletSelectorRowViewModel]
}
