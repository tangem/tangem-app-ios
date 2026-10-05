//
//  PolymarketMainActionStates.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PolymarketMainActionStates: Equatable {
    let addFunds: PolymarketMainViewModel.ActionState
    let withdraw: PolymarketMainViewModel.WithdrawState

    init(
        readiness: PolymarketAccountFundsInteractor.State,
        collateralBalance: TokenBalanceType,
        withdrawMinimum: Decimal?
    ) {
        switch readiness {
        case .loading:
            addFunds = .loading
            withdraw = .loading

        case .ready(let readiness):
            addFunds = readiness.depositTargets.isEmpty ? .unavailable : .available
            withdraw = Self.withdrawState(collateralBalance: collateralBalance, minimum: withdrawMinimum)

        case .unavailable:
            addFunds = .unavailable
            withdraw = .unavailable(.accountUnavailable)
        }
    }
}

// MARK: - Private implementation

private extension PolymarketMainActionStates {
    static func withdrawState(
        collateralBalance: TokenBalanceType,
        minimum: Decimal?
    ) -> PolymarketMainViewModel.WithdrawState {
        switch collateralBalance {
        case .loaded(let balance):
            return withdrawState(forBalance: balance, minimum: minimum)
        case .loading(.some(let cached)), .failure(.some(let cached)):
            return withdrawState(forBalance: cached.balance, minimum: minimum)
        case .loading:
            return .loading
        case .empty, .failure:
            return .unavailable(.balanceUnavailable)
        }
    }

    static func withdrawState(forBalance balance: Decimal, minimum: Decimal?) -> PolymarketMainViewModel.WithdrawState {
        guard balance > 0 else {
            return .unavailable(.emptyBalance)
        }

        guard let minimum, balance < minimum else {
            return .available
        }

        return .unavailable(.tooSmallBalance(minimumFormatted: PolymarketOrderFormatter.money(minimum)))
    }
}
