//
//  MCPConnectionRequestInteractor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct MCPConnectionRequestInteractor: Sendable {
    let fetchRequest: FetchMCPConnectionRequest
    let ensurePushNotificationsAuthorized: EnsurePushNotificationsAuthorized
    let retrieveUserWalletRegistrationStatus: RetrieveUserWalletRegistrationStatus
    let reject: RejectMCPConnection
    let accept: AcceptMCPConnection
}
