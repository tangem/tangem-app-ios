//
//  EnsurePushNotificationsAuthorizedUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

typealias EnsurePushNotificationsAuthorized = @Sendable () async -> Bool

struct EnsurePushNotificationsAuthorizedUseCase: Sendable {
    let provider: any MCPPushNotificationsPermissionProvider

    func callAsFunction() async -> Bool {
        await provider.ensureAuthorized()
    }
}
