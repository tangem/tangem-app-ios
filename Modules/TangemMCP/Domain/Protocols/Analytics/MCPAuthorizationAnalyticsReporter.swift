//
//  MCPAuthorizationAnalyticsReporter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol MCPAuthorizationAnalyticsReporter: Sendable {
    func reportConnectionReceived()
    func reportAgentConnectionRequested(agent: MCPAgent)
    func reportApproveButtonTapped(agent: MCPAgent)
    func reportAgentConnected(agent: MCPAgent)
    func reportDeclineButtonTapped(agent: MCPAgent)
    func reportAuthorizationFailed(errorCode: Int)
    func reportPushPermissionRequired()
}
