//
//  MCPSendIntentProposalState.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import enum TangemLocalization.Localization

public typealias MCPSendIntentViewModel = MCPIntentViewModel<MCPSendIntentProposalState>

public struct MCPSendIntentProposalState: Equatable {
    let tokenIcon: MCPTokenIconState
    let title: String
    let intentDescription: MCPIntentProposalDescriptionSection
    let proceedButtonTitle: String

    public init(agent: MCPAgent, amount: String, token: MCPToken) {
        tokenIcon = MCPTokenIconState(token: token)
        title = Localization.mcpSendIntentOfferTitle(agent.host ?? Localization.mcpIntentUnknownAgentName, amount)

        intentDescription = MCPIntentProposalDescriptionSection(
            agent: agent,
            body: Localization.mcpSendIntentOfferDescription
        )

        proceedButtonTitle = Localization.mcpIntentProceed
    }
}
