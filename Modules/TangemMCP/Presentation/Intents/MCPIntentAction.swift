//
//  MCPIntentAction.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MCPIntentAction<IntentProposalState: Equatable> {
    case navigationCloseButtonTapped
    case issueTerminated
    case issueRetryResultReceived(MCPIntentLoadingResult<IntentProposalState>)
}
