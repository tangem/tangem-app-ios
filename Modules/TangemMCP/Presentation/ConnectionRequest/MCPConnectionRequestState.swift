//
//  MCPConnectionRequestState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
enum MCPConnectionRequestState: Hashable {
    case proposal(MCPConnectionRequestProposalViewModel)
    case userWalletSelector(MCPConnectionRequestUserWalletSelectorViewModel)
    case agentConnected(MCPConnectionRequestAgentConnectedViewModel)
}
