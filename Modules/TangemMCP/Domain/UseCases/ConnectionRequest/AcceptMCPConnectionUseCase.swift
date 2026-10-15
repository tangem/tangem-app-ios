//
//  AcceptMCPConnectionUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.UserWalletId

struct AcceptMCPConnectionUseCase: Sendable {
    let pushNotificationsPermissionProvider: any MCPPushNotificationsPermissionProvider
    let client: any MCPConnectionClient

    func callAsFunction(request: MCPConnectionRequest, for userWalletID: UserWalletId) async throws(AcceptMCPConnectionError) {
        guard await pushNotificationsPermissionProvider.ensureAuthorized() else {
            throw AcceptMCPConnectionError.pushNotificationsDisabled
        }

        do {
            try await client.accept(request: request, userWalletID: userWalletID)
        } catch {
            throw AcceptMCPConnectionError.clientFailure(error)
        }
    }
}
