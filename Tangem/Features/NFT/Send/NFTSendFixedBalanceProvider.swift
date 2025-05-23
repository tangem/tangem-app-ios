//
//  NFTSendFixedBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// A dummy balance provider with a constant value.
final class NFTSendFixedBalanceProvider {
    private let tokenItem: TokenItem
    private let fixedValue: Decimal
    private let balanceFormatter: BalanceFormatter

    init(
        tokenItem: TokenItem,
        fixedValue: Decimal
    ) {
        self.tokenItem = tokenItem
        self.fixedValue = fixedValue
        balanceFormatter = BalanceFormatter()
    }

    private func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let currencyCode = tokenItem.currencySymbol
        let builder = FormattedTokenBalanceTypeBuilder(format: { [balanceFormatter] value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: currencyCode)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}

// MARK: - TokenBalanceProvider protocol conformance

extension NFTSendFixedBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        .loaded(fixedValue)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        .just(output: balanceType)
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
