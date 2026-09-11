//
//  PolymarketCollateralBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class PolymarketCollateralBalanceProvider {
    private let tokenItem: TokenItem
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceSubject: CurrentValueSubject<LoadingResult<Decimal, Error>?, Never>

    private let walletModelId: WalletModelId
    private let balanceFormatter = BalanceFormatter()

    private var balanceSubscription: AnyCancellable?

    init(
        tokenItem: TokenItem,
        tokenBalancesRepository: TokenBalancesRepository,
        balanceSubject: CurrentValueSubject<LoadingResult<Decimal, Error>?, Never>
    ) {
        self.tokenItem = tokenItem
        self.tokenBalancesRepository = tokenBalancesRepository
        self.balanceSubject = balanceSubject

        walletModelId = WalletModelId(tokenItem: tokenItem)

        bind()
    }
}

// MARK: - TokenBalanceProvider protocol conformance

extension PolymarketCollateralBalanceProvider: TokenBalanceProvider {
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

// MARK: - Private implementation

private extension PolymarketCollateralBalanceProvider {
    func bind() {
        balanceSubscription = balanceSubject
            .compactMap { result -> Decimal? in
                switch result {
                case .success(let balance): balance
                case .none, .loading, .failure: nil
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
            type: .available
        )
    }

    func cachedBalance() -> TokenBalanceType.Cached? {
        tokenBalancesRepository
            .balance(walletModelId: walletModelId, type: .available)
            .map { .init(balance: $0.balance, date: $0.date) }
    }

    func mapToTokenBalanceType(balance: LoadingResult<Decimal, Error>?) -> TokenBalanceType {
        switch balance {
        case .none, .loading:
            .loading(cachedBalance())
        case .failure:
            .failure(cachedBalance())
        case .success(let balance):
            .loaded(balance)
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
