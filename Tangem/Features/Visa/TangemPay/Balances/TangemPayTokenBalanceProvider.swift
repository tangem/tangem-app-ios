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
    private let balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>, Never>
    private let balanceFormatter = BalanceFormatter()

    init(balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>, Never>) {
        self.balanceSubject = balanceSubject
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
        mapToFormattedTokenBalanceType(balance: balanceSubject.value)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceSubject
            .map { mapToFormattedTokenBalanceType(balance: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension TangemPayTokenBalanceProvider {
    func mapToTokenBalanceType(balance: LoadingResult<TangemPayBalance, Error>) -> TokenBalanceType {
        switch balance {
        case .loading: .loading(.none)
        case .failure: .failure(.none)
        case .success(let balance): .loaded(balance.availableBalance)
        }
    }

    func mapToFormattedTokenBalanceType(balance: LoadingResult<TangemPayBalance, Error>) -> FormattedTokenBalanceType {
        switch balance {
        case .loading: .loading(.empty(BalanceFormatter.defaultEmptyBalanceString))
        case .failure: .failure(.empty(BalanceFormatter.defaultEmptyBalanceString))
        case .success(let balance): .loaded(
                balanceFormatter.formatFiatBalance(balance.availableBalance, currencyCode: balance.currency)
            )
        }
    }
}
