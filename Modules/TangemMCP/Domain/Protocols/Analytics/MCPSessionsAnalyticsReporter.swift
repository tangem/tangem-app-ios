//
//  MCPSessionsAnalyticsReporter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol MCPSessionsAnalyticsReporter: Sendable {
    func reportAgentDisconnected(agent: MCPAgent)
}
