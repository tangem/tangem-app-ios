//
//  MCPSessionClientError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum MCPSessionClientError: Error {
    case fetchFailed(underlying: any Error)
    case sessionNotFound
    case revokeFailed(underlying: any Error)
    case revokeAllFailed(underlying: any Error)
}
