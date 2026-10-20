//
//  FetchMCPConnectionRequestUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FetchMCPConnectionRequestUseCase: Sendable {
    let client: any MCPConnectionClient

    func callAsFunction(userCode: String) async throws(MCPConnectionClientError) -> MCPConnectionRequest {
        try await client.fetch(userCode: userCode)
    }
}
