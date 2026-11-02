//
//  MCPSwapIntentProposalState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]

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
            title: "\(agent.name) wants to swap \(fromAmount.formattedValue) to \(toToken.symbol)"
        )
    }

    public init(agent: MCPAgent, fromToken: MCPToken, toAmount: MCPSwapAmount) {
        self.init(
            agent: agent,
            fromToken: fromToken,
            toToken: toAmount.token,
            title: "\(agent.name) wants to swap \(fromToken.symbol) to \(toAmount.formattedValue)"
        )
    }

    private init(agent: MCPAgent, fromToken: MCPToken, toToken: MCPToken, title: String) {
        fromTokenIcon = MCPTokenIconState(token: fromToken)
        toTokenIcon = MCPTokenIconState(token: toToken)
        self.title = title

        intentDescription = MCPIntentProposalDescriptionSection(
            agent: agent,
            body: "The agent is asking to send from your account. You’ll review the details next."
        )

        proceedButtonTitle = "Proceed"
    }
}
