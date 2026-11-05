//
//  FetchMCPSessionsUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct FetchMCPSessionsUseCase: Sendable {
    let client: any MCPSessionClient

    public func callAsFunction() async throws(MCPSessionClientError) -> [MCPSession] {
        try await client.fetchAll()
    }
}
