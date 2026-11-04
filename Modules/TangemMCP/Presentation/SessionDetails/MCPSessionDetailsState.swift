//
//  MCPSessionDetailsState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import enum TangemLocalization.Localization
import enum TangemUI.ThumbnailWalletViewType

struct MCPSessionDetailsState: Equatable {
    let title = Localization.mcpSessionTitle
    let connectionDate: String
    let agent: MCPAgent
    let userWallet: Self.UserWalletRow
    var revokeButton = Self.RevokeButton()
}

extension MCPSessionDetailsState {
    struct UserWalletRow: Equatable {
        let title = Localization.commonWallet
        let name: String
        let thumbnail: ThumbnailWalletViewType?
    }

    struct RevokeButton: Equatable {
        let title = Localization.mcpSessionRevokeAccess
        var isLoading = false
    }
}
