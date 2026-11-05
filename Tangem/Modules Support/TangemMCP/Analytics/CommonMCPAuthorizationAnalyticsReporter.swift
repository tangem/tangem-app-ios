//
//  CommonMCPAuthorizationAnalyticsReporter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemMCP.MCPAgent
import protocol TangemMCP.MCPAuthorizationAnalyticsReporter

struct CommonMCPAuthorizationAnalyticsReporter: MCPAuthorizationAnalyticsReporter {
    func reportConnectionReceived() {
        let event = Analytics.Event.mcpAuthorizationConnectionReceived
        Analytics.log(event)
    }

    func reportAgentConnectionRequested(agent: MCPAgent) {
        let event = Analytics.Event.mcpAuthorizationAgentConnectionRequested
        report(event, agent: agent)
    }

    func reportApproveButtonTapped(agent: MCPAgent) {
        let event = Analytics.Event.mcpAuthorizationApproveButtonTapped
        report(event, agent: agent)
    }

    func reportAgentConnected(agent: MCPAgent) {
        let event = Analytics.Event.mcpAuthorizationAgentConnected
        report(event, agent: agent)
    }

    func reportDeclineButtonTapped(agent: MCPAgent) {
        let event = Analytics.Event.mcpAuthorizationDeclineButtonTapped
        report(event, agent: agent)
    }

    func reportAuthorizationFailed(errorCode: Int) {
        let event = Analytics.Event.mcpAuthorizationFailed
        Analytics.log(event: event, params: [Analytics.ParameterKey.errorCode: String(errorCode)])
    }

    func reportPushPermissionRequired() {
        let event = Analytics.Event.mcpAuthorizationPushPermissionRequired
        Analytics.log(event)
    }

    private func report(_ event: Analytics.Event, agent: MCPAgent) {
        Analytics.log(event: event, params: [Analytics.ParameterKey.mcpAgentName: agent.host ?? agent.name ?? Analytics.ParameterValue.unknown.rawValue])
    }
}
