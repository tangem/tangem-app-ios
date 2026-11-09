//
//  FetchMCPAgentUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemLogger.Logger

public struct FetchMCPAgentUseCase: Sendable {
    let client: any MCPAgentClient
    let logger: TangemLogger.Logger

    public func callAsFunction(agentID: String) async -> MCPAgent {
        do {
            return try await client.fetch(agentID: agentID)
        } catch {
            logger.error("Failed to fetch MCP agent metadata. Switching to a fallback agent", error: error)
            return MCPAgent(id: agentID, name: nil, host: nil, icon: nil)
        }
    }
}
