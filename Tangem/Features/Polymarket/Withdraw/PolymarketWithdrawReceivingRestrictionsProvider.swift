//
//  PolymarketWithdrawReceivingRestrictionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PolymarketWithdrawReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
    func restriction(expectAmount: Decimal) -> ReceivedRestriction? {
        nil
    }
}
