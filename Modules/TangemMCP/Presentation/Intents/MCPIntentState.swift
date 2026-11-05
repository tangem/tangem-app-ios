//
//  MCPIntentState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MCPIntentState<IntentProposalState: Equatable>: Equatable {
    case issue(MCPIntentIssueViewModel)
    case proposal(MCPIntentProposalViewModel<IntentProposalState>)
}
