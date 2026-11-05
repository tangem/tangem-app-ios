//
//  MCPSessionDetailsState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import enum TangemLocalization.Localization
import enum TangemUI.ThumbnailWalletViewType

struct MCPSessionDetailsState: Equatable {
    let title = Localization.mcpSessionTitle
    let connectionDate: String
    let agent: Self.AgentRow
    let userWallet: Self.UserWalletRow
    var revokeButton = Self.RevokeButton()
}

extension MCPSessionDetailsState {
    struct AgentRow: Equatable {
        let name: String
        let host: String
        let iconURL: URL?

        init(agent: MCPAgent) {
            name = agent.name ?? MCPAgent.fallbackName
            host = agent.host ?? MCPAgent.fallbackHost
            iconURL = agent.icon
        }
    }

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
