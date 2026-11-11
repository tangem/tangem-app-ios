//
//  TangemPayMoneyAccountRowState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

enum TangemPayMoneyAccountRowState: Equatable {
    case activating
    case awaitingDeposit
    case failed
    case active(balance: FormattedTokenBalanceType, isCached: Bool)
}

extension TangemPayMoneyAccountRowState {
    init?(moneyAccountState: TangemPayMoneyAccountState?, isKYCIncomplete: Bool, isCached: Bool) {
        switch moneyAccountState {
        case .active(let moneyAccount):
            self = .active(balance: moneyAccount.fiatBalance, isCached: isCached)
        case .activating(let moneyAccount) where !isKYCIncomplete:
            self = moneyAccount.activation.step == .awaitingDeposit ? .awaitingDeposit : .activating
        case .activationFailed where !isKYCIncomplete:
            self = .failed
        case .activating, .activationFailed, .notStarted, .deactivated, .loading, .syncNeeded, .unavailable, .none:
            return nil
        }
    }
}

extension TangemPayMoneyAccountState {
    var isResolved: Bool {
        switch self {
        case .loading, .syncNeeded, .unavailable:
            false
        case .notStarted, .activating, .activationFailed, .active, .deactivated:
            true
        }
    }
}
