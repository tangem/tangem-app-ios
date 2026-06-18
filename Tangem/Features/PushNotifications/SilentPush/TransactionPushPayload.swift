//
//  TransactionPushPayload.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validated representation of a transactional push notification payload.
///
/// Shared by the two entry points that need it: the user-tap path
/// (`CommonIncomingActionManager`, which turns it into a `tangem://token` deeplink) and the
/// foreground silent-push path (`TransactionPushPortfolioUpdater`, which uses it to refresh the
/// portfolio without navigating). Keeping the key/type parsing in one place guarantees both
/// paths agree on what counts as a transactional push.
struct TransactionPushPayload {
    let type: IncomingActionConstants.DeeplinkType
    let networkId: String
    let tokenId: String
    let userWalletId: String
    let derivationPath: String?
    let transactionId: String?

    /// Fails if any required field is missing or the `type` isn't a known transactional one.
    /// String values equal to `"null"` are treated as absent — the backend sends the literal
    /// string for empty optionals.
    init?(userInfo: [AnyHashable: Any]) {
        let params = IncomingActionConstants.DeeplinkParams.self

        let nonNullString: (String) -> String? = { key in
            guard let value = userInfo[key] as? String, value != "null" else {
                return nil
            }
            return value
        }

        guard
            let networkId = nonNullString(params.networkId),
            let tokenId = nonNullString(params.tokenId),
            let userWalletId = nonNullString(params.userWalletId),
            let rawType = nonNullString(params.type),
            let type = IncomingActionConstants.DeeplinkType(rawValue: rawType)
        else {
            return nil
        }

        self.type = type
        self.networkId = networkId
        self.tokenId = tokenId
        self.userWalletId = userWalletId
        derivationPath = nonNullString(params.derivationPath)
        transactionId = nonNullString(params.transactionId)
    }
}
