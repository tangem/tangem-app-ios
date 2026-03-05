//
//  ReceivingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol ReceivingRestrictionsProvider {
    func restriction(expectAmount: Decimal) -> ReceivedRestriction?
}

enum ReceivedRestriction {
    case notEnoughReceivedAmount(minAmount: Decimal)
}
