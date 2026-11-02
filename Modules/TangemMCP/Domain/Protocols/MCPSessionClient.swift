//
//  MCPSessionClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.UserWalletId

protocol MCPSessionClient: Sendable {
    func fetchAll() async throws(MCPSessionClientError) -> [MCPSession]
    func revoke(sessionID: MCPSession.ID) async throws(MCPSessionClientError)
    func revokeAll(userWalletID: UserWalletId) async throws(MCPSessionClientError)
}
