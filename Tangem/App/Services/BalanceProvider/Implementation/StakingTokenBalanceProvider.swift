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

protocol StakingTokenBalanceProviderInput: AnyObject {
    var stakingManagerState: StakingManagerState { get }
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> { get }
}

struct StakingTokenBalanceProvider {
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
        self.input = input
        self.walletModelId = walletModelId
        self.tokenItem = tokenItem
        self.tokenBalancesRepository = tokenBalancesRepository
    }
}

// MARK: - TokenBalanceProvider

extension StakingTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        guard let input else {
            assertionFailure("StakingTokenBalanceProviderInput not found")
            return .empty(.noData)
        }

        return mapToTokenBalance(state: input.stakingManagerState)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        guard let input else {
            assertionFailure("StakingTokenBalanceProviderInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.stakingManagerStatePublisher
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
    func storeBalance(balance: Decimal) {
        let balance = CachedBalance(balance: balance, date: .now)
        tokenBalancesRepository.store(balance: balance, for: walletModelId, type: .staked)
    }

    func cachedBalance() -> TokenBalanceType.Cached? {
        tokenBalancesRepository
            .balance(walletModelId: walletModelId, type: .staked)
            .map { .init(balance: $0.balance, date: $0.date) }
    }

    func mapToTokenBalance(state: StakingManagerState) -> TokenBalanceType {
        switch state {
        case .loading:
            return .loading(cachedBalance())
        case .notEnabled, .temporaryUnavailable:
            return .empty(.noData)
        case .loadingError:
            return .failure(cachedBalance())
        case .availableToStake:
            storeBalance(balance: .zero)
            return .loaded(.zero)
        case .staked(let balances):
            let balance = balances.balances.blocked().sum()
            storeBalance(balance: balance)
            return .loaded(balance)
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: tokenItem.currencySymbol)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
