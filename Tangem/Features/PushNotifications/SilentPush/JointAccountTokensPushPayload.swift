//
//  JointAccountTokensPushPayload.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountTokensPushPayload {
    let userWalletId: String
    let accountId: String

    init?(userInfo: [AnyHashable: Any]) {
        let params = IncomingActionConstants.DeeplinkParams.self

        guard
            userInfo.nonNullString(TokenDeeplink.Keys.type) == IncomingActionConstants.DeeplinkType.jointTokens.rawValue,
            let userWalletId = userInfo.nonNullString(params.userWalletId),
            let accountId = userInfo.nonNullString(params.accountId)
        else {
            return nil
        }

        self.userWalletId = userWalletId
        self.accountId = accountId.lowercased()
    }
}
