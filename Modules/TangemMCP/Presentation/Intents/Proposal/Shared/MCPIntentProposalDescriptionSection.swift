//
//  MCPIntentProposalDescriptionSection.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL

// [REDACTED_TODO_COMMENT]
struct MCPIntentProposalDescriptionSection: Equatable {
    let agent: AgentHeader
    let body: String

    init(agent: MCPAgent, body: String) {
        self.agent = AgentHeader(iconURL: agent.icon, host: agent.host)
        self.body = body
    }
}

extension MCPIntentProposalDescriptionSection {
    struct AgentHeader: Equatable {
        let iconURL: URL?
        let host: String
    }
}
