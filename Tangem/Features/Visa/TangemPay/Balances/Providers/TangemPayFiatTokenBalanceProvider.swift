//
//  TangemPayFiatTokenBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa

/// Provider with constant USD fiat value `1:1`
struct TangemPayFiatTokenBalanceProvider {
    private let cryptoBalanceProvider: TokenBalanceProvider
    private let balanceFormatter = BalanceFormatter()

    private let fiatItem: FiatItem = TangemPayUtilities.fiatItem

    init(cryptoBalanceProvider: TokenBalanceProvider) {
        self.cryptoBalanceProvider = cryptoBalanceProvider
    }
}

// MARK: - TokenBalanceProvider

extension TangemPayFiatTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        cryptoBalanceProvider.balanceType
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        cryptoBalanceProvider.balanceTypePublisher
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

extension TangemPayFiatTokenBalanceProvider {
    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { value in
            balanceFormatter.formatFiatBalance(value, currencyCode: fiatItem.currencyCode)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
