//
//  PolymarketOrderNotification+WithdrawState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

extension PolymarketOrderNotification {
    init(withdrawState: PolymarketWithdrawState) {
        switch withdrawState {
        case .inProgress, .unknown: self = .withdrawalInProgress
        case .confirmed: self = .withdrawalSent
        case .failed: self = .withdrawalFailed
        }
    }
}
