//
//  MCPSessionDetailsAction.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MCPSessionDetailsAction {
    case closeButtonTapped
    case revokeButtonTapped
    case sessionRevoked(Result<Void, MCPSessionClientError>)
}
