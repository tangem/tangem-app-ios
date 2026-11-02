//
//  MCPSendIntentProposalStateTests.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemAssets
@testable import TangemMCP

struct MCPSendIntentProposalStateTests {
    @Test
    func showsAgentAndAmount() {
        let agent = MCPAgent(id: "claude.ai", name: "Claude", host: "claude.ai", icon: nil)

        let state = MCPSendIntentProposalState(agent: agent, amount: "42.00 USDT", token: Self.usdt)

        #expect(state.title == "Claude wants to send 42.00 USDT")
        #expect(state.intentDescription.agent.host == "claude.ai")
    }

    @Test
    func showsFallbackAgentWhenAgentIsUnknown() {
        let agent = MCPAgent(id: "claude.ai", name: nil, host: nil, icon: nil)

        let state = MCPSendIntentProposalState(agent: agent, amount: "42.00 USDT", token: Self.usdt)

        #expect(state.title == "AI Agent wants to send 42.00 USDT")
        #expect(state.intentDescription.agent.host == "mcp.tangem.org")
    }

    @Test
    func carriesTokenIconAndProposalCopy() {
        let agentIcon = URL(string: "https://example.com/agent.png")
        let agent = MCPAgent(id: "claude.ai", name: "Claude", host: "claude.ai", icon: agentIcon)

        let state = MCPSendIntentProposalState(agent: agent, amount: "42.00 USDT", token: Self.usdt)

        #expect(state.tokenIcon == MCPTokenIconState(token: Self.usdt))
        #expect(state.intentDescription.agent == MCPIntentProposalDescriptionSection.AgentHeader(iconURL: agentIcon, host: "claude.ai"))
        #expect(state.intentDescription.body == "The agent is asking to send from your account. You’ll review the details next.")
        #expect(state.proceedButtonTitle == "Proceed")
    }

    @Test
    func showsCoinIconWithoutNetworkBadgeForNativeCoin() throws {
        let coinIconURL = try #require(URL(string: "https://example.com/ethereum.png"))
        let ether = MCPToken(
            displayName: "Ethereum",
            symbol: "ETH",
            network: MCPToken.Blockchain(iconAsset: Tokens.ethereumFill),
            kind: .nativeCoin(iconURL: coinIconURL)
        )

        let tokenIcon = MCPTokenIconState(token: ether)

        #expect(tokenIcon.iconURL == coinIconURL)
        #expect(tokenIcon.networkIconAsset == nil)
        #expect(!tokenIcon.isCustom)
    }

    @Test
    func showsTokenIconWithNetworkBadgeForToken() {
        let tokenIcon = MCPTokenIconState(token: Self.usdt)

        #expect(tokenIcon.iconURL == URL(string: "https://example.com/usdt.png"))
        #expect(tokenIcon.networkIconAsset == Tokens.ethereumFill)
        #expect(!tokenIcon.isCustom)
    }

    @Test
    func showsNetworkBadgeWithoutIconForCustomToken() {
        let customToken = MCPToken(
            displayName: "Custom",
            symbol: "CST",
            network: MCPToken.Blockchain(iconAsset: Tokens.ethereumFill),
            kind: .customToken
        )

        let tokenIcon = MCPTokenIconState(token: customToken)

        #expect(tokenIcon.iconURL == nil)
        #expect(tokenIcon.networkIconAsset == Tokens.ethereumFill)
        #expect(tokenIcon.isCustom)
    }

    private static let usdt = MCPToken(
        displayName: "Tether",
        symbol: "USDT",
        network: MCPToken.Blockchain(iconAsset: Tokens.ethereumFill),
        kind: .token(iconURL: URL(string: "https://example.com/usdt.png")!)
    )
}
