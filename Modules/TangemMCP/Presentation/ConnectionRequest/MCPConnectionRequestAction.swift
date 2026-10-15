//
//  MCPConnectionRequestAction.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.UserWalletId

enum MCPConnectionRequestAction {
    case backButtonTapped
    case closeButtonTapped
    case openSystemSettingsButtonTapped

    case userWalletSelectorTapped
    case userWalletSelectionUpdated(MCPUserWallet)

    case fetchRequestFailed(MCPConnectionClientError)
    case agentConnectionRejected(Result<Void, MCPConnectionClientError>)
    case agentConnectionAccepted(Result<String, AcceptMCPConnectionError>)
}
