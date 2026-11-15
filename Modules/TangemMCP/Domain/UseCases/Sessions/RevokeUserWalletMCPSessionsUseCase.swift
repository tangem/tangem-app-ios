//
//  RevokeUserWalletMCPSessionsUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId

public struct RevokeUserWalletMCPSessionsUseCase: Sendable {
    let client: any MCPSessionClient

    public func callAsFunction(for userWalletID: UserWalletId) async throws(MCPSessionClientError) {
        try await client.revokeAll(userWalletID: userWalletID)
    }
}
