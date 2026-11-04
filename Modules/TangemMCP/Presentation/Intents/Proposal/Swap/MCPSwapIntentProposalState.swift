//
//  MCPSwapIntentProposalState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import enum TangemLocalization.Localization

public typealias MCPSwapIntentViewModel = MCPIntentViewModel<MCPSwapIntentProposalState>

public struct MCPSwapIntentProposalState: Equatable {
    let fromTokenIcon: MCPTokenIconState
    let toTokenIcon: MCPTokenIconState
    let title: String
    let intentDescription: MCPIntentProposalDescriptionSection
    let proceedButtonTitle: String

    public init(agent: MCPAgent, fromAmount: MCPSwapAmount, toToken: MCPToken) {
        self.init(
            agent: agent,
            fromToken: fromAmount.token,
            toToken: toToken,
            title: Localization.mcpSwapIntentOfferTitle(
                agent.host ?? Localization.mcpIntentUnknownAgentName,
                fromAmount.formattedValue,
                toToken.symbol
            )
        )
    }

    public init(agent: MCPAgent, fromToken: MCPToken, toAmount: MCPSwapAmount) {
        self.init(
            agent: agent,
            fromToken: fromToken,
            toToken: toAmount.token,
            title: Localization.mcpSwapIntentOfferTitle(
                agent.host ?? Localization.mcpIntentUnknownAgentName,
                fromToken.symbol,
                toAmount.formattedValue
            )
        )
    }

    private init(agent: MCPAgent, fromToken: MCPToken, toToken: MCPToken, title: String) {
        fromTokenIcon = MCPTokenIconState(token: fromToken)
        toTokenIcon = MCPTokenIconState(token: toToken)
        self.title = title

        intentDescription = MCPIntentProposalDescriptionSection(
            agent: agent,
            body: Localization.mcpSwapIntentOfferDescription
        )

        proceedButtonTitle = Localization.mcpIntentProceed
    }
}
