//
//  MCPSendIntentProposalState.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]

public typealias MCPSendIntentViewModel = MCPIntentViewModel<MCPSendIntentProposalState>

public struct MCPSendIntentProposalState: Equatable {
    let tokenIcon: MCPTokenIconState
    let title: String
    let intentDescription: MCPIntentProposalDescriptionSection
    let proceedButtonTitle: String

    public init(agent: MCPAgent, amount: String, token: MCPToken) {
        tokenIcon = MCPTokenIconState(token: token)
        title = "\(agent.name) wants to send \(amount)"

        intentDescription = MCPIntentProposalDescriptionSection(
            agent: agent,
            body: "The agent is asking to send from your account. You’ll review the details next."
        )

        proceedButtonTitle = "Proceed"
    }
}
