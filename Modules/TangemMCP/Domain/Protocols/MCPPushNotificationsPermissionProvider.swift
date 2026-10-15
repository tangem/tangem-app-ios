//
//  MCPPushNotificationsPermissionProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol MCPPushNotificationsPermissionProvider: Sendable {
    func ensureAuthorized() async -> Bool
}
