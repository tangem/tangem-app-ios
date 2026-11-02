//
//  RevokeMCPSessionUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemLogger.Logger

public struct RevokeMCPSessionUseCase: Sendable {
    let client: any MCPSessionClient
    let logger: TangemLogger.Logger

    public func callAsFunction(sessionID: MCPSession.ID) async throws(MCPSessionClientError) {
        do {
            try await client.revoke(sessionID: sessionID)
        } catch MCPSessionClientError.sessionNotFound {
            logger.warning("Session was already revoked")
        }
    }
}
