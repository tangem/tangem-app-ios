//
//  TangemPayReceivingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
    func restriction(expectAmount: Decimal) -> ReceivedRestriction? {
        // TangemPay doesn't have receiving restrictions
        return nil
    }
}
