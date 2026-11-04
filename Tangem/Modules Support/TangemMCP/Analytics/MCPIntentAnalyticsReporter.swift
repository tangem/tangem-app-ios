//
//  MCPIntentAnalyticsReporter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemMCP.MCPAgent

struct MCPIntentAnalyticsReporter {
    let intentType: IntentType

    func reportIntentReceived(intentID: String, source: String) {
        let event = Analytics.Event.mcpIntentReceived
        Analytics.log(
            event: event,
            params: [
                Analytics.ParameterKey.mcpIntentType: intentType.rawValue,
                Analytics.ParameterKey.source: source,
                Analytics.ParameterKey.mcpIntentId: intentID,
            ]
        )
    }

    func reportLoadEvent(_ loadEvent: LoadEvent, intentID: String) {
        switch loadEvent {
        case .screenOpened(let agent, let tokenItem):
            reportIntentScreenOpened(intentID: intentID, agent: agent, tokenItem: tokenItem)

        case .loadFailed(let reason, let errorCode):
            reportIntentLoadFailed(intentID: intentID, reason: reason, errorCode: errorCode)
        }
    }

    private func reportIntentScreenOpened(intentID: String, agent: MCPAgent, tokenItem: TokenItem) {
        let event = Analytics.Event.mcpIntentScreenOpened
        Analytics.log(
            event: event,
            params: [
                Analytics.ParameterKey.mcpIntentType: intentType.rawValue,
                Analytics.ParameterKey.mcpAgentName: agent.host ?? agent.name ?? Analytics.ParameterValue.unknown.rawValue,
                Analytics.ParameterKey.blockchain: tokenItem.blockchain.displayName,
                Analytics.ParameterKey.token: tokenItem.currencySymbol,
                Analytics.ParameterKey.mcpIntentId: intentID,
            ]
        )
    }

    func reportIntentLoadFailed(intentID: String, reason: LoadFailureReason, errorCode: String? = nil) {
        let event = Analytics.Event.mcpIntentLoadFailed

        var params = [
            Analytics.ParameterKey.mcpIntentType: intentType.rawValue,
            Analytics.ParameterKey.reason: reason.rawValue,
            Analytics.ParameterKey.mcpIntentId: intentID,
        ]

        if let errorCode {
            params[Analytics.ParameterKey.errorCode] = errorCode
        }

        Analytics.log(event: event, params: params)
    }

    func reportContinueButtonTapped(intentID: String) {
        let event = Analytics.Event.mcpIntentContinueButtonTapped
        Analytics.log(
            event: event,
            params: [
                Analytics.ParameterKey.mcpIntentType: intentType.rawValue,
                Analytics.ParameterKey.mcpIntentId: intentID,
            ]
        )
    }

    // [REDACTED_TODO_COMMENT]
    func reportIntentCompleted(intentID: String, tokenItem: TokenItem) {
        let event = Analytics.Event.mcpIntentCompleted
        Analytics.log(
            event: event,
            params: [
                Analytics.ParameterKey.mcpIntentType: intentType.rawValue,
                Analytics.ParameterKey.blockchain: tokenItem.blockchain.displayName,
                Analytics.ParameterKey.token: tokenItem.currencySymbol,
                Analytics.ParameterKey.mcpIntentId: intentID,
            ]
        )
    }

    func reportIntentReportFailed(intentID: String, errorCode: String) {
        let event = Analytics.Event.mcpIntentReportFailed
        Analytics.log(
            event: event,
            params: [
                Analytics.ParameterKey.mcpIntentType: intentType.rawValue,
                Analytics.ParameterKey.errorCode: errorCode,
                Analytics.ParameterKey.mcpIntentId: intentID,
            ]
        )
    }
}

// MARK: - Nested types

extension MCPIntentAnalyticsReporter {
    enum IntentType: String {
        case exchange
        case send
    }

    enum LoadEvent {
        case screenOpened(agent: MCPAgent, tokenItem: TokenItem)
        case loadFailed(reason: LoadFailureReason, errorCode: String?)
    }

    enum LoadFailureReason: String {
        case notFound = "Not Found"
        case wrongWallet = "Wrong Wallet"
        case unreachable = "Unreachable"
        case alreadyProcessed = "Already Processed"
        case tokenMissing = "Token Missing"
        case invalidAmount = "Invalid Amount"
        case sendNotOpened = "Send Not Opened"
        case unknown = "Unknown"
    }
}
