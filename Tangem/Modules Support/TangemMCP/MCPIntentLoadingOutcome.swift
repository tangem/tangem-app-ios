//
//  MCPIntentLoadingOutcome.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemMCP.MCPAgent
import struct TangemMCP.MCPIntentIssue
import enum TangemMCP.MCPIntentLoadingResult

struct MCPIntentLoadingOutcome<IntentProposalState: Equatable> {
    let result: MCPIntentLoadingResult<IntentProposalState>
    let analyticsEvent: MCPIntentAnalyticsReporter.LoadEvent
}

extension MCPIntentLoadingOutcome {
    static func loaded(
        _ result: MCPIntentLoadingResult<IntentProposalState>,
        agent: MCPAgent,
        tokenItem: TokenItem
    ) -> Self {
        Self(result: result, analyticsEvent: .screenOpened(agent: agent, tokenItem: tokenItem))
    }

    static func failed(
        _ issue: MCPIntentIssue,
        reason: MCPIntentAnalyticsReporter.LoadFailureReason,
        errorCode: String? = nil
    ) -> Self {
        Self(result: .issue(issue), analyticsEvent: .loadFailed(reason: reason, errorCode: errorCode))
    }
}
