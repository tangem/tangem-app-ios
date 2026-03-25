//
//  TangemPaySendingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPaySendingRestrictionsProvider: SendingRestrictionsProvider {
    var sendingRestrictions: SendingRestrictions? {
        // TangemPay doesn't have sending restrictions
        return nil
    }
}
