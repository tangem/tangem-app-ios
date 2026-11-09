//
//  MCPAgentClientError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MCPAgentClientError: Error {
    case fetchFailed(underlying: any Error)
}
