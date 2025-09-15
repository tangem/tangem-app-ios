//
//  YieldModuleTokenBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol YieldModuleTokenBalanceProviderInput: AnyObject {
    var yieldModuleManagerState: YieldModuleWalletManagerState? { get }
    var yieldModuleManagerStatePublisher: AnyPublisher<YieldModuleWalletManagerState, Never> { get }
}

/// Used as available balance when yield module is active
class YieldModuleTokenBalanceProvider {
    private weak var input: YieldModuleTokenBalanceProviderInput?

    private let walletModelId: WalletModelId
    private let tokenItem: TokenItem
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceFormatter = BalanceFormatter()

    init(
        input: YieldModuleTokenBalanceProviderInput,
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

extension YieldModuleTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        guard let strongInput = input else {
            assertionFailure("StakingTokenBalanceProviderInput not found")
            return .empty(.noData)
        }

        return mapToYieldModuleBalance(state: strongInput.yieldModuleManagerState)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        guard let strongInput = input else {
            assertionFailure("StakingTokenBalanceProviderInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return strongInput.yieldModuleManagerStatePublisher
            .map { self.mapToYieldModuleBalance(state: $0) }
            .eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        mapToFormattedYieldModuleBalanceType(type: balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceTypePublisher
            .map { self.mapToFormattedYieldModuleBalanceType(type: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension YieldModuleTokenBalanceProvider {
    func storeBalance(balance: Decimal) {
        let balance = CachedBalance(balance: balance, date: .now)
        tokenBalancesRepository.store(balance: balance, for: walletModelId, type: .yieldModule)
    }

    func cachedBalance() -> TokenBalanceType.Cached? {
        tokenBalancesRepository
            .balance(walletModelId: walletModelId, type: .yieldModule)
            .map { .init(balance: $0.balance, date: $0.date) }
    }

    func mapToYieldModuleBalance(state: YieldModuleWalletManagerState?) -> TokenBalanceType {
        switch state {
        case .none, .notEnabled:
            return .empty(.noData)
        case .enabled(.loading):
            return .loading(cachedBalance())
        case .enabled(.loaded(let state)):
            let balance = state.smartContractState.balance ?? .zero
            storeBalance(balance: balance)
            return .loaded(balance)
        case .enabled(.failedToLoad): return .failure(cachedBalance())
        }
    }

    func mapToFormattedYieldModuleBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let currencyCode = tokenItem.currencySymbol
        let builder = FormattedTokenBalanceTypeBuilder(format: { [balanceFormatter] value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: currencyCode)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
