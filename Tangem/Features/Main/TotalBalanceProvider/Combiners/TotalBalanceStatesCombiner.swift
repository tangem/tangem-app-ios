//
//  TotalBalanceStatesCombiner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct TotalBalanceStatesCombiner {
    func mapToTotalBalanceState(states: [TotalBalanceState]) -> TotalBalanceState {
        if states.isEmpty {
            return .loaded(balance: 0)
        }

        let hasEmpty = states.contains { $0.isEmpty }
        if hasEmpty {
            return .empty
        }

        let hasLoading = states.contains { $0.isLoading }
        // Show it in loading state if only one is in loading process
        if hasLoading {
            let loadingBalance = cachedBalance(states: states)
            return .loading(cached: loadingBalance)
        }

        let failureBalances = states.filter { $0.isFailed }
        let hasError = !failureBalances.isEmpty
        if hasError {
            // If has error and cached balance then show the failed state with cached balances
            let cachedBalance = cachedBalance(states: states)
            return .failed(cached: cachedBalance, failedItems: failureBalances.flatMap(\.failedItems))
        }

        let loadedBalance = loadedBalance(states: states)
        return .loaded(balance: loadedBalance)
    }
}

// MARK: - Private

private extension TotalBalanceStatesCombiner {
    func cachedBalance(states: [TotalBalanceState]) -> Decimal? {
        let cachedBalances = states.compactMap { balanceType -> Decimal? in
            switch balanceType {
            case .loading(.some(let cached)), .failed(.some(let cached), _):
                return cached
            case .loaded(let balance):
                return balance
            default:
                return nil
            }
        }

        if cachedBalances.isEmpty {
            return nil
        }

        // The cached balance is showable only if all tokens have some balance value
        if cachedBalances.count == states.count {
            return cachedBalances.reduce(0, +)
        }

        return nil
    }

    func loadedBalance(states: [TotalBalanceState]) -> Decimal {
        let loadedBalance = states.compactMap { balance in
            switch balance {
            case .loaded(let balance):
                return balance
            // If we don't balance because custom token don't have rates
            // Or it's address with noAccount state
            // Just calculate it as `.zero`
            default:
                assertionFailure("Balance not found \(balance)")
                return nil
            }
        }

        return loadedBalance.sum()
    }
}

private extension TotalBalanceState {
    var isEmpty: Bool {
        switch self {
        case .empty: true
        default: false
        }
    }

    var isFailed: Bool {
        switch self {
        case .failed: true
        default: false
        }
    }

    var failedItems: [TokenItem] {
        switch self {
        case .failed(_, let items): items
        default: []
        }
    }
}
