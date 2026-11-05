//
//  RevokeDeviceMCPSessionsUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct RevokeDeviceMCPSessionsUseCase: Sendable {
    let client: any MCPSessionClient

    public func callAsFunction() async throws(MCPSessionClientError) {
        try await client.revokeAll()
    }
}
