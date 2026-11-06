//
//  TangemPayMoneyAccountState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay
import TangemMacro

@CaseFlagable
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

// MARK: - Mapping from customer summary status

extension TangemPayMoneyAccountState {
    init(
        activationStatus: TangemPayCustomerSummaryResponse.Activation.Status,
        moneyAccount: () -> (any TangemPayMoneyAccountModel)?
    ) {
        let makeState: (any TangemPayMoneyAccountModel) -> Self

        switch activationStatus {
        case .notStarted:
            self = .notStarted
            return
        case .unavailable, .undefined:
            self = .unavailable
            return
        case .processing:
            makeState = Self.activating
        case .failed:
            makeState = Self.activationFailed
        case .completed:
            makeState = Self.active
        case .deactivated:
            makeState = Self.deactivated
        }

        self = moneyAccount().map(makeState) ?? .syncNeeded
    }
}

// MARK: - Helpers

extension TangemPayMoneyAccountState {
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
