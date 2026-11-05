//
//  MCPIntentLoadingResult.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum MCPIntentLoadingResult<IntentProposalState: Equatable> {
    case issue(MCPIntentIssue)
    case proposal(IntentProposalState, proceedAction: () -> Void)
}
