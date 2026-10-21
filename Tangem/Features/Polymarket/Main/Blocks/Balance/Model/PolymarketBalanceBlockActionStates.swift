//
//  PolymarketBalanceBlockActionStates.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PolymarketBalanceBlockActionStates: Equatable {
    let addFunds: PolymarketAccountFundsInteractor.AddFundsAvailability
    let withdraw: PolymarketBalanceBlockViewModel.WithdrawState

    init(
        readiness: PolymarketAccountFundsInteractor.State,
        collateralBalance: TokenBalanceType,
        usdToToken: (Decimal) -> Decimal,
        isWithdrawalPending: Bool
    ) {
        addFunds = readiness.addFundsAvailability

        switch readiness {
        case .loading:
            withdraw = .loading
        case .ready where isWithdrawalPending:
            withdraw = .unavailable(.withdrawalInProgress)
        case .ready(let readiness):
            withdraw = Self.withdrawState(
                withdrawalAvailability: readiness.withdrawalAvailability,
                collateralBalance: collateralBalance,
                usdToToken: usdToToken
            )
        case .unavailable:
            withdraw = .unavailable(.accountUnavailable)
        }
    }
}

// MARK: - Private implementation

private extension PolymarketBalanceBlockActionStates {
    static func withdrawState(
        withdrawalAvailability: PolymarketAccountFundsInteractor.WithdrawalAvailability,
        collateralBalance: TokenBalanceType,
        usdToToken: (Decimal) -> Decimal
    ) -> PolymarketBalanceBlockViewModel.WithdrawState {
        switch withdrawalAvailability {
        case .available(let minimumUSD):
            withdrawState(collateralBalance: collateralBalance, minimum: usdToToken(minimumUSD))
        case .unavailable:
            .unavailable(.minimumUnknown)
        }
    }

    static func withdrawState(
        collateralBalance: TokenBalanceType,
        minimum: Decimal
    ) -> PolymarketBalanceBlockViewModel.WithdrawState {
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

    static func withdrawState(forBalance balance: Decimal, minimum: Decimal) -> PolymarketBalanceBlockViewModel.WithdrawState {
        guard balance > 0 else {
            return .unavailable(.emptyBalance)
        }

        guard balance < minimum else {
            return .available
        }

        return .unavailable(.tooSmallBalance(minimumFormatted: PolymarketOrderFormatter.money(minimum)))
    }
}
