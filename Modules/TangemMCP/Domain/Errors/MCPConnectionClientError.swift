//
//  MCPConnectionClientError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MCPConnectionClientError: Error {
    case fetchFailed(underlying: any Error)
    case acceptFailed(underlying: any Error)
    case rejectFailed(underlying: any Error)
    case connectionRequestNotFound
}
