//
//  MCPSwapIntentState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import struct TangemAssets.ImageType

// [REDACTED_TODO_COMMENT]
// [REDACTED_TODO_COMMENT]
struct MCPSwapIntentState: Equatable {
    let fromTokenIcon: TokenIconState
    let toTokenIcon: TokenIconState
    let title: String
    let intentDescription: IntentDescriptionSection
    let proceedButtonTitle: String

    init(agent: MCPAgent, amount: String, from fromToken: MCPToken, to toToken: MCPToken) {
        fromTokenIcon = TokenIconState(token: fromToken)
        toTokenIcon = TokenIconState(token: toToken)

        title = "\(agent.name) wants to swap \(amount) \(fromToken.symbol) to \(toToken.symbol)"

        intentDescription = IntentDescriptionSection(
            agent: AgentHeader(iconURL: agent.icon, host: agent.host),
            body: "The agent is asking to send from your account. You’ll review the details next."
        )

        proceedButtonTitle = "Proceed"
    }
}

extension MCPSwapIntentState {
    struct TokenIconState: Equatable {
        let source: TokenIconSource
        let isCustom: Bool
        let accessibilityIdentifier: String

        var localIconAsset: ImageType? {
            switch source {
            case .local(let asset): asset
            case .remote: nil
            }
        }

        var remoteIconURL: URL? {
            switch source {
            case .local: nil
            case .remote(let url): url
            }
        }

        init(token: MCPToken) {
            switch token.kind {
            case .nativeCoin:
                source = .local(token.network.iconAsset)
            case .token(let remoteIconURL):
                source = .remote(remoteIconURL)
            case .customToken:
                source = .remote(nil)
            }

            isCustom = token.hasCustomDerivation || token.kind == .customToken
            accessibilityIdentifier = token.displayName
        }
    }

    enum TokenIconSource: Equatable {
        case local(ImageType)
        case remote(URL?)
    }

    struct IntentDescriptionSection: Equatable {
        let agent: AgentHeader
        let body: String
    }

    struct AgentHeader: Equatable {
        let iconURL: URL?
        let host: String
    }
}
