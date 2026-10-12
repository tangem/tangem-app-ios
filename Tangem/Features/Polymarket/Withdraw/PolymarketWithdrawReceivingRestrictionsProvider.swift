//
//  PolymarketWithdrawReceivingRestrictionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PolymarketWithdrawReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
    var isRestrictionKnown: Bool { true }

    func restriction(expectAmount: Decimal) async throws -> ReceivedRestriction? {
        nil
    }
}
