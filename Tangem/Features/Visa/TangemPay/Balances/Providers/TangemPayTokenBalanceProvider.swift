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
import TangemPay

final class TangemPayTokenBalanceProvider {
    private let tokenItem: TokenItem
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>
    private let keyPath: KeyPath<TangemPayBalance, Decimal>

    private let walletModelId: WalletModelId
    private let balanceFormatter: BalanceFormatter

    private var statePublisherSubscription: AnyCancellable?

    init(
        tokenItem: TokenItem,
        tokenBalancesRepository: TokenBalancesRepository,
        balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>,
        keyPath: KeyPath<TangemPayBalance, Decimal>
    ) {
        self.tokenItem = tokenItem
        self.tokenBalancesRepository = tokenBalancesRepository
        self.balanceSubject = balanceSubject
        self.keyPath = keyPath

        walletModelId = .init(tokenItem: tokenItem)
        balanceFormatter = .init()

        bind(to: balanceSubject)
    }
}

// MARK: - TokenBalanceProvider

extension TangemPayTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToTokenBalanceType(balance: balanceSubject.value)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        balanceSubject
            .withWeakCaptureOf(self)
            .map { provider, balance in
                provider.mapToTokenBalanceType(balance: balance)
            }
            .eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        mapToFormattedTokenBalanceType(type: balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceTypePublisher
            .withWeakCaptureOf(self)
            .map { provider, balanceType in
                provider.mapToFormattedTokenBalanceType(type: balanceType)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension TangemPayTokenBalanceProvider {
    func bind(to balanceSubject: some Subject<LoadingResult<TangemPayBalance, Error>?, Never>) {
        statePublisherSubscription = balanceSubject
            .compactMap { [keyPath] state -> Decimal? in
                switch state {
                case .success(let balance):
                    return balance[keyPath: keyPath]
                case .none,
                     .loading,
                     .failure:
                    return nil
                }
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { provider, balance in
                provider.storeBalance(balance: balance)
            }
    }

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
            return .loaded(.zero)
        case .loading:
            return .loading(cachedBalance())
        case .failure:
            return .failure(cachedBalance())
        case .success(let balance):
            let targetBalance = balance[keyPath: keyPath]
            return .loaded(targetBalance)
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
