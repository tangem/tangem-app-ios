//
//  StakingTokenBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking
import TangemFoundation

protocol StakingTokenBalanceProviderInput: AnyObject {
    var stakingManagerState: StakingManagerState { get }
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> { get }
}

struct NotSupportedStakingTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType { .loaded(0) }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { .just(output: balanceType) }
    var formattedBalanceType: FormattedTokenBalanceType { .loaded("0") }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { .just(output: formattedBalanceType) }
}

class StakingTokenBalanceProvider {
    private weak var input: StakingTokenBalanceProviderInput?

    private let walletModelId: WalletModelId
    private let tokenItem: TokenItem
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceFormatter = BalanceFormatter()

    init(
        input: StakingTokenBalanceProviderInput,
        walletModelId: WalletModelId,
        tokenItem: TokenItem,
        tokenBalancesRepository: TokenBalancesRepository
    ) {
        self.walletModelId = walletModelId
        self.tokenItem = tokenItem
        self.tokenBalancesRepository = tokenBalancesRepository
        self.input = input
    }
}

// MARK: - TokenBalanceProvider

extension StakingTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        guard let strongInput = input else {
            assertionFailure("StakingTokenBalanceProviderInput not found")
            return .empty(.noData)
        }

        return mapToTokenBalance(state: strongInput.stakingManagerState)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        guard let strongInput = input else {
            assertionFailure("StakingTokenBalanceProviderInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return strongInput.stakingManagerStatePublisher
            .map { self.mapToTokenBalance(state: $0) }
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

extension StakingTokenBalanceProvider {
    func oldCachedBalance() -> TokenBalanceType.Cached? {
        tokenBalancesRepository
            .balance(walletModelId: walletModelId, type: .staked)
            .map { .init(balance: $0.balance, date: $0.date) }
    }

    func mapToTokenBalance(state: StakingManagerState) -> TokenBalanceType {
        switch state {
        case .loading(.some(let cached)):
            return .loading(.init(balance: cached.stakeState.balance, date: cached.date))
        case .loading(.none):
            return .loading(oldCachedBalance())
        case .notEnabled:
            return .empty(.noData)
        case .loadingError(_, .some(let cached)), .temporaryUnavailable(_, .some(let cached)):
            return .failure(.init(balance: cached.stakeState.balance, date: cached.date))
        case .temporaryUnavailable:
            return .empty(.noData)
        case .loadingError(_, .none):
            return .failure(oldCachedBalance())
        case .availableToStake:
            return .loaded(.zero)
        case .staked(let balances):
            let balance = balances.balances.blocked().sum()
            return .loaded(balance)
        // Region block is not an error: surface the cached balance as `.loaded` so the
        // aggregated token total stays clean (a `.failure` here would poison the total).
        case .unavailableInRegion(.some(let cached)):
            return .loaded(cached.stakeState.balance)
        case .unavailableInRegion(.none):
            return .empty(.noData)
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let currencyCode = tokenItem.currencySymbol
        let builder = FormattedTokenBalanceTypeBuilder(format: { [balanceFormatter] value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: currencyCode)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
