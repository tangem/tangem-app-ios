//
//  AvailableTokenBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol AvailableTokenBalanceProviderInput: AnyObject {
    var walletModelState: WalletModelState { get }
    var walletModelStatePublisher: AnyPublisher<WalletModelState, Never> { get }

    var yieldModuleManagerState: YieldModuleWalletManagerState? { get }
    var yieldModuleManagerStatePublisher: AnyPublisher<YieldModuleWalletManagerState, Never> { get }
}

/// Just simple available to use (e.g. send) balance
class AvailableTokenBalanceProvider {
    private weak var input: AvailableTokenBalanceProviderInput?

    private let walletModelId: WalletModelId
    private let tokenItem: TokenItem
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceFormatter = BalanceFormatter()

    init(
        input: AvailableTokenBalanceProviderInput,
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

extension AvailableTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        guard let strongInput = input else {
            assertionFailure("StakingTokenBalanceProviderInput not found")
            return .empty(.noData)
        }

        switch strongInput.yieldModuleManagerState {
        case .enabled(.loading):
            return mapToTokenBalance(yieldModuleManagerState: .loading)
        case .enabled(.loaded(let state)) where state.smartContractState.balance != nil:
            return mapToTokenBalance(yieldModuleManagerState: .loaded(state))
        default:
            return mapToTokenBalance(state: strongInput.walletModelState)
        }
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        guard let strongInput = input else {
            assertionFailure("StakingTokenBalanceProviderInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return strongInput.walletModelStatePublisher
            .combineLatest(strongInput.yieldModuleManagerStatePublisher)
            .map { walletModelState, yieldModuleState in
                switch yieldModuleState {
                case .enabled(.loading):
                    return self.mapToTokenBalance(yieldModuleManagerState: .loading)
                case .enabled(.loaded(let state)) where state.smartContractState.balance != nil:
                    return self.mapToTokenBalance(yieldModuleManagerState: .loaded(state))
                default:
                    return self.mapToTokenBalance(state: walletModelState)
                }
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

private extension AvailableTokenBalanceProvider {
    func storeBalance(balance: Decimal) {
        let balance = CachedBalance(balance: balance, date: .now)
        tokenBalancesRepository.store(balance: balance, for: walletModelId, type: .available)
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

    func mapToTokenBalance(yieldModuleManagerState: LoadingValue<YieldModuleWalletManagerStateInfo>) -> TokenBalanceType {
        switch yieldModuleManagerState {
        case .loading:
            return .loading(cachedBalance())
        case .loaded(let state):
            let balance = state.smartContractState.balance ?? .zero
            storeBalance(balance: balance)
            return .loaded(balance)
        case .failedToLoad: return .failure(cachedBalance())
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
