//
//  MCPIntentProposalDescriptionSection.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL

struct MCPIntentProposalDescriptionSection: Equatable {
    let agent: AgentHeader
    let body: String

    init(agent: MCPAgent, body: String) {
        self.agent = AgentHeader(iconURL: agent.icon, host: agent.host ?? MCPAgent.fallbackHost)
        self.body = body
    }
}

extension MCPIntentProposalDescriptionSection {
    struct AgentHeader: Equatable {
        let iconURL: URL?
        let host: String
    }
}
