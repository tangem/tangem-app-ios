//
//  MCPSwapIntentState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]
public struct MCPSwapIntentState: Equatable {
    let fromTokenIcon: MCPIntentTokenIconState
    let toTokenIcon: MCPIntentTokenIconState
    let title: String
    let intentDescription: MCPIntentDescriptionSection
    let proceedButtonTitle: String

    init(agent: MCPAgent, fromAmount: MCPSwapAmount, toToken: MCPToken) {
        self.init(
            agent: agent,
            fromToken: fromAmount.token,
            toToken: toToken,
            title: "\(agent.name) wants to swap \(fromAmount.formattedValue) to \(toToken.symbol)"
        )
    }

    init(agent: MCPAgent, fromToken: MCPToken, toAmount: MCPSwapAmount) {
        self.init(
            agent: agent,
            fromToken: fromToken,
            toToken: toAmount.token,
            title: "\(agent.name) wants to swap \(fromToken.symbol) to \(toAmount.formattedValue)"
        )
    }

    private init(agent: MCPAgent, fromToken: MCPToken, toToken: MCPToken, title: String) {
        fromTokenIcon = MCPIntentTokenIconState(token: fromToken)
        toTokenIcon = MCPIntentTokenIconState(token: toToken)
        self.title = title

        intentDescription = MCPIntentDescriptionSection(agent: agent)

        proceedButtonTitle = "Proceed"
    }
}
