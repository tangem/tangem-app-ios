//
//  MCPSendIntentState.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]
public struct MCPSendIntentState: Equatable {
    let tokenIcon: MCPIntentTokenIconState
    let title: String
    let intentDescription: MCPIntentDescriptionSection
    let proceedButtonTitle: String

    init(agent: MCPAgent, amount: String, token: MCPToken) {
        tokenIcon = MCPIntentTokenIconState(token: token)
        title = "\(agent.name) wants to send \(amount)"

        intentDescription = MCPIntentDescriptionSection(agent: agent)

        proceedButtonTitle = "Proceed"
    }
}
