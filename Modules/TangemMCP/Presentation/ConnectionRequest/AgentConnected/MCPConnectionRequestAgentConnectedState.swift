//
//  MCPConnectionRequestAgentConnectedState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]
struct MCPConnectionRequestAgentConnectedState: Equatable {
    let title = "Agent connected"
    let body: String
    let doneButtonTitle = "Done"

    init(agentName: String) {
        body = "\(agentName) can now view your balances and request transaction approvals. Revoke access anytime in Connections."
    }
}
