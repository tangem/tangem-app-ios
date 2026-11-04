//
//  MCP+UniversalError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import protocol TangemFoundation.UniversalError
import enum TangemLocalization.Localization

// `Subsystems`:
// `001` - MCPSessionClientError

extension MCPSessionClientError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .fetchFailed:
            115001000
        case .sessionNotFound:
            115001001
        case .revokeFailed:
            115001002
        case .revokeAllFailed:
            115001003
        }
    }

    public var errorDescription: String? {
        switch self {
        case .fetchFailed:
            "MCP sessions fetch failed."
        case .sessionNotFound:
            "MCP session not found."
        case .revokeFailed, .revokeAllFailed:
            Localization.mcpSessionRevokeFailed
        }
    }
}
