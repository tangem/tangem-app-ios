//
//  CommonMCPSessionsAnalyticsReporter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemMCP.MCPAgent
import protocol TangemMCP.MCPSessionsAnalyticsReporter

struct CommonMCPSessionsAnalyticsReporter: MCPSessionsAnalyticsReporter {
    func reportAgentDisconnected(agent: MCPAgent) {
        let event = Analytics.Event.mcpSessionsAgentDisconnected
        let agentName = agent.host ?? agent.name ?? Analytics.ParameterValue.unknown.rawValue
        Analytics.log(event: event, params: [Analytics.ParameterKey.mcpAgentName: agentName])
    }
}
