//
//  RejectMCPConnectionUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct RejectMCPConnectionUseCase: Sendable {
    let client: any MCPConnectionClient

    func callAsFunction(request: MCPConnectionRequest) async throws(MCPConnectionClientError) {
        try await client.reject(request: request)
    }
}
