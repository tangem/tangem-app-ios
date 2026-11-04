//
//  ConnectionsViewAction.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemMCP.MCPSession

enum ConnectionsViewAction {
    case viewDidAppear
    case disconnectAllButtonTapped
    case tabSelected(ConnectionsViewState.UserWalletTab.ID)
    case mcpSessionsReloadButtonTapped
    case mcpSessionTapped(MCPSession)
    case dAppTapped(WalletConnectConnectedDApp)
    case closeDialogButtonTapped
    case newConnectionButtonTapped
}
