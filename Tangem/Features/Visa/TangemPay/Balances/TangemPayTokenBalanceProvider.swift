//
//  TangemPayTokenBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemFoundation

struct TangemPayTokenBalanceProvider {
    private let tokenItem: TokenItem
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>

    private let walletModelId: WalletModelId
    private let balanceFormatter: BalanceFormatter

    init(
        tokenItem: TokenItem,
        tokenBalancesRepository: TokenBalancesRepository,
        balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>
    ) {
        self.tokenItem = tokenItem
        self.tokenBalancesRepository = tokenBalancesRepository
        self.balanceSubject = balanceSubject

        walletModelId = .init(tokenItem: tokenItem)
        balanceFormatter = .init()
    }
}

// MARK: - TokenBalanceProvider

extension TangemPayTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToTokenBalanceType(balance: balanceSubject.value)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        balanceSubject
            .map { mapToTokenBalanceType(balance: $0) }
            .eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        mapToFormattedTokenBalanceType(type: balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceTypePublisher
            .map { mapToFormattedTokenBalanceType(type: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension TangemPayTokenBalanceProvider {
    func storeBalance(balance: Decimal) {
        let balance = CachedBalance(balance: balance, date: .now)
        tokenBalancesRepository.store(balance: balance, for: walletModelId, type: .available)
    }

    func cachedBalance() -> TokenBalanceType.Cached? {
        tokenBalancesRepository
            .balance(walletModelId: walletModelId, type: .available)
            .map { .init(balance: $0.balance, date: $0.date) }
    }

    func mapToTokenBalanceType(balance: LoadingResult<TangemPayBalance, Error>?) -> TokenBalanceType {
        switch balance {
        case .none:
            return .empty(.noData)
        case .loading:
            return .loading(cachedBalance())
        case .failure:
            return .failure(cachedBalance())
        case .success(let balance):
            storeBalance(balance: balance.fiat.availableBalance)
            return .loaded(balance.fiat.availableBalance)
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { [balanceFormatter] value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: tokenItem.currencySymbol)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
