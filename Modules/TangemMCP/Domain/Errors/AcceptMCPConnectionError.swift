//
//  AcceptMCPConnectionError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum AcceptMCPConnectionError: Error {
    case pushNotificationsDisabled
    case clientFailure(MCPConnectionClientError)
}
