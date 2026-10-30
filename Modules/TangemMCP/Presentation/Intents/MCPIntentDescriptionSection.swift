//
//  MCPIntentDescriptionSection.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL

struct MCPIntentDescriptionSection: Equatable {
    let agent: AgentHeader
    let body: String
}

extension MCPIntentDescriptionSection {
    struct AgentHeader: Equatable {
        let iconURL: URL?
        let host: String
    }
}

// [REDACTED_TODO_COMMENT]
extension MCPIntentDescriptionSection {
    init(agent: MCPAgent) {
        self.init(
            agent: AgentHeader(iconURL: agent.icon, host: agent.host),
            body: "The agent is asking to send from your account. You’ll review the details next."
        )
    }
}
