//
//  PolymarketWithdrawBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct PolymarketWithdrawBalanceProvider {
    let base: any TokenBalanceProvider
    let tokenItem: TokenItem

    private static let balanceFormatter = BalanceFormatter()
}

// MARK: - TokenBalanceProvider protocol conformance

extension PolymarketWithdrawBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        base.balanceType
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        base.balanceTypePublisher
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        formatted(base.balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        base.balanceTypePublisher
            .map(formatted)
            .eraseToAnyPublisher()
    }
}

// MARK: - Private implementation

private extension PolymarketWithdrawBalanceProvider {
    func formatted(_ type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { [tokenItem] value in
            Self.balanceFormatter.formatCryptoBalance(value, currencyCode: tokenItem.currencySymbol)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
