//
//  MCPConnectionClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.UserWalletId

protocol MCPConnectionClient: Sendable {
    func fetch(userCode: String) async throws(MCPConnectionClientError) -> MCPConnectionRequest
    func accept(request: MCPConnectionRequest, userWalletID: UserWalletId) async throws(MCPConnectionClientError)
    func reject(request: MCPConnectionRequest) async throws(MCPConnectionClientError)
}
