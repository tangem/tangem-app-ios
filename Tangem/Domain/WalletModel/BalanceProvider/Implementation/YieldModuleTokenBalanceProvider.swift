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
    var state: WalletModelState { get }
    var statePublisher: AnyPublisher<WalletModelState, Never> { get }
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

        return mapToTokenBalance(state: strongInput.state)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        guard let strongInput = input else {
            assertionFailure("StakingTokenBalanceProviderInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return strongInput.statePublisher
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

private extension YieldModuleTokenBalanceProvider {
    func storeBalance(balance: Decimal) {
        let balance = CachedBalance(balance: balance, date: .now)
        tokenBalancesRepository.store(balance: balance, for: walletModelId, type: .yieldModule)
    }

    func cachedBalance() -> TokenBalanceType.Cached? {
        tokenBalancesRepository
            .balance(walletModelId: walletModelId, type: .available)
            .map { .init(balance: $0.balance, date: $0.date) }
    }

    func mapToTokenBalance(state: WalletModelState) -> TokenBalanceType {
        // The `binance` always has zero balance
        if case .binance = tokenItem.blockchain {
            return .loaded(0)
        }

        switch state {
        case .created:
            // Return `.loading` because we assume
            // that loading should start anyway
            // and to avoid any UI empty states
            return .loading(cachedBalance())
        case .loading:
            return .loading(cachedBalance())
        case .loaded(let balance):
            storeBalance(balance: balance)
            return .loaded(balance)
        case .noAccount(let message, _):
            storeBalance(balance: .zero)
            return .empty(.noAccount(message: message))
        case .failed:
            return .failure(cachedBalance())
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
