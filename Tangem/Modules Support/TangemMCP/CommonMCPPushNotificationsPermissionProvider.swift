//
//  CommonMCPPushNotificationsPermissionProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol TangemMCP.MCPPushNotificationsPermissionProvider

struct CommonMCPPushNotificationsPermissionProvider: MCPPushNotificationsPermissionProvider {
    nonisolated(unsafe) let service: any PushNotificationsPermissionService

    func ensureAuthorized() async -> Bool {
        await service.ensureAuthorized()
    }
}
