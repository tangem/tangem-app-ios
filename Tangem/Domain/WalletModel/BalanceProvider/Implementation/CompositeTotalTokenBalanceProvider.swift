//
//  CompositeTotalTokenBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

/// Total crypto balance: a required base provider (available) plus the sources the compositors fold in
/// (staking, future yield providers). Toggle-gated replacement for `TotalTokenBalanceProvider`.
///
/// The compositors are fixed for the provider's lifetime, so every source they name has to stay in place and
/// report `.empty` while it has nothing to contribute — the way `StakingTokenBalanceProvider` does when
/// staking is not enabled. Leaving one out until it becomes relevant omits its balance for the rest of the
/// process instead.
final class CompositeTotalTokenBalanceProvider {
    private let tokenItem: TokenItem
    private let base: TokenBalanceProvider
    private let compositors: [any TokenBalanceCompositor]
    private let now: () -> Date

    private let balanceFormatter = BalanceFormatter()

    init(
        tokenItem: TokenItem,
        base: TokenBalanceProvider,
        compositors: [any TokenBalanceCompositor],
        now: @escaping () -> Date = { .now }
    ) {
        self.tokenItem = tokenItem
        self.base = base
        self.compositors = compositors
        self.now = now
    }
}

// MARK: - TokenBalanceProvider

extension CompositeTotalTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToTokenBalance(
            base: base.balanceType,
            contributions: compositors.map { $0.balanceProvider.balanceType }
        )
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Publishers.CombineLatest(base.balanceTypePublisher, contributionsPublisher)
            .map { base, contributions in
                self.mapToTokenBalance(base: base, contributions: contributions)
            }
            .eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        mapToFormattedTokenBalanceType(type: balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceTypePublisher
            .map { self.mapToFormattedTokenBalanceType(type: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CompositeTotalTokenBalanceProvider {
    /// Emits the compositors' source states, in the order the compositors fold them.
    var contributionsPublisher: AnyPublisher<[TokenBalanceType], Never> {
        // CombineExt's `combineLatest()` returns `Empty()` for an empty collection — the total would never emit
        compositors.isEmpty
            ? .just(output: [])
            : compositors.map { $0.balanceProvider.balanceTypePublisher }.combineLatest()
    }

    func mapToTokenBalance(base: TokenBalanceType, contributions: [TokenBalanceType]) -> TokenBalanceType {
        // No base balance -> no balance, whatever the contributors have
        if case .empty(let reason) = base {
            return .empty(reason)
        }

        // Without a base value a partial total is never shown. Legacy quirk kept for parity:
        // a cacheless loading contributor flips even a failed base to loading, a cached one doesn't.
        guard let baseBalance = base.value else {
            let hasCachelessLoadingContributor = contributions.contains { $0 == .loading(nil) }
            return base.isLoading || hasCachelessLoadingContributor ? .loading(nil) : .failure(nil)
        }

        let composition = zip(compositors, contributions).reduce(
            TotalTokenBalanceComposition(base: base, balance: baseBalance)
        ) { composition, entry in
            entry.0.compose(composition, with: entry.1)
        }

        let date = base.cached?.date ?? composition.cacheDates.min() ?? now()

        if composition.isLoading {
            return .loading(.init(balance: composition.balance, date: date))
        }

        if base.isFailure {
            return .failure(.init(balance: composition.balance, date: date))
        }

        return .loaded(composition.balance)
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let tokenItem = tokenItem
        let builder = FormattedTokenBalanceTypeBuilder(format: { [balanceFormatter] value in
            balanceFormatter.formatCryptoBalance(value, tokenItem: tokenItem)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
