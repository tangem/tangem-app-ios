//
//  MCPAgentClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol MCPAgentClient: Sendable {
    func fetch(agentID: String) async throws(MCPAgentClientError) -> MCPAgent
}
