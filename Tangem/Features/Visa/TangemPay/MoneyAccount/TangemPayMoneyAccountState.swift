//
//  TangemPayMoneyAccountState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

enum TangemPayMoneyAccountState {
    case loading
    case syncNeeded
    case unavailable
    case notStarted
    case activating(any TangemPayMoneyAccountModel)
    case activationFailed(any TangemPayMoneyAccountModel)
    case active(any TangemPayMoneyAccountModel)
    case deactivated(any TangemPayMoneyAccountModel)
}

extension TangemPayMoneyAccountState {
    init(
        activationStatus: TangemPayCustomerSummaryResponse.Activation.Status,
        moneyAccount: () -> any TangemPayMoneyAccountModel
    ) {
        switch activationStatus {
        case .notStarted:
            self = .notStarted
        case .processing:
            self = .activating(moneyAccount())
        case .failed:
            self = .activationFailed(moneyAccount())
        case .completed:
            self = .active(moneyAccount())
        case .deactivated:
            self = .deactivated(moneyAccount())
        case .unavailable, .undefined:
            self = .unavailable
        }
    }

    var moneyAccount: (any TangemPayMoneyAccountModel)? {
        switch self {
        case .activating(let moneyAccount),
             .activationFailed(let moneyAccount),
             .active(let moneyAccount),
             .deactivated(let moneyAccount):
            moneyAccount
        case .loading, .syncNeeded, .unavailable, .notStarted:
            nil
        }
    }
}
