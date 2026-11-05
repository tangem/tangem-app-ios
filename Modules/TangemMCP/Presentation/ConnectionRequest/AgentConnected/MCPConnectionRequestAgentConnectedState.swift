//
//  MCPConnectionRequestAgentConnectedState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import enum TangemLocalization.Localization

struct MCPConnectionRequestAgentConnectedState: Equatable {
    let title = Localization.mcpConnectionSuccessTitle
    let body: String
    let doneButtonTitle = Localization.commonDone

    init(agentName: String) {
        body = Localization.mcpConnectionSuccessDescription(agentName)
    }
}
