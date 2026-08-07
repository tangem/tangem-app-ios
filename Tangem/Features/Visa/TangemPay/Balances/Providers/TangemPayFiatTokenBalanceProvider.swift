//
//  TangemPayFiatTokenBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemPay

/// Provider with constant USD fiat value `1:1`
struct TangemPayFiatTokenBalanceProvider {
    private let cryptoBalanceProvider: TokenBalanceProvider
    private let balanceFormatter = BalanceFormatter()

    private let fiatItem: FiatItem = TangemPayUtilities.fiatItem

    private let fiatFormatter = {
        let formatter = BalanceFormatter().makeDefaultFiatFormatter(
            forCurrencyCode: TangemPayUtilities.fiatItem.currencyCode,
            formattingOptions: .defaultFiatFormattingOptions
        )
        formatter.positiveFormat = "¤#,##0.00"
        formatter.negativeFormat = "-¤#,##0.00"
        return formatter
    }()

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
            balanceFormatter.formatFiatBalance(value, currencyCode: fiatItem.currencyCode, formatter: fiatFormatter)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
