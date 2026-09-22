//
//  PolymarketAccountBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class PolymarketAccountBalanceProvider {
    enum Kind {
        case available
        case total
    }

    private let kind: Kind
    private let tokenItem: TokenItem
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceSubject: CurrentValueSubject<PolymarketBalanceState?, Never>

    private let walletModelId: WalletModelId
    private let balanceFormatter = BalanceFormatter()

    private var balanceSubscription: AnyCancellable?

    init(
        kind: Kind,
        tokenItem: TokenItem,
        tokenBalancesRepository: TokenBalancesRepository,
        balanceSubject: CurrentValueSubject<PolymarketBalanceState?, Never>
    ) {
        self.kind = kind
        self.tokenItem = tokenItem
        self.tokenBalancesRepository = tokenBalancesRepository
        self.balanceSubject = balanceSubject

        walletModelId = WalletModelId(tokenItem: tokenItem)

        bind()
    }
}

// MARK: - TokenBalanceProvider protocol conformance

extension PolymarketAccountBalanceProvider: TokenBalanceProvider {
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

// MARK: - Kind

extension PolymarketAccountBalanceProvider.Kind {
    var cachedBalanceType: CachedBalanceType {
        switch self {
        case .available: .available
        case .total: .total
        }
    }

    func amount(from balance: PolymarketBalance) -> Decimal? {
        switch self {
        case .available: balance.available
        case .total: balance.total
        }
    }

    func rememberableAmount(from balance: PolymarketBalance) -> Decimal? {
        switch self {
        case .available: balance.available
        case .total: balance.freshTotal
        }
    }
}

// MARK: - Private implementation

private extension PolymarketAccountBalanceProvider {
    func bind() {
        balanceSubscription = balanceSubject
            .compactMap { [kind] state -> Decimal? in
                switch state {
                case .loaded(let balance): kind.rememberableAmount(from: balance)
                case .none, .loading, .failed, .unavailable: nil
                }
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { provider, balance in
                provider.storeBalance(balance)
            }
    }

    func storeBalance(_ balance: Decimal) {
        tokenBalancesRepository.store(
            balance: CachedBalance(balance: balance, date: .now),
            for: walletModelId,
            type: kind.cachedBalanceType
        )
    }

    func cachedBalance() -> TokenBalanceType.Cached? {
        tokenBalancesRepository
            .balance(walletModelId: walletModelId, type: kind.cachedBalanceType)
            .map { .init(balance: $0.balance, date: $0.date) }
    }

    func mapToTokenBalanceType(balance: PolymarketBalanceState?) -> TokenBalanceType {
        switch balance {
        case .none, .loading:
            .loading(cachedBalance())
        case .failed:
            .failure(cachedBalance())
        case .unavailable:
            .empty(.custom)
        case .loaded(let balance):
            kind.amount(from: balance).map { .loaded($0) } ?? .failure(cachedBalance())
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
