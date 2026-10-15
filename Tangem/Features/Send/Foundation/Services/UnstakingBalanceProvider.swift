//
//  UnstakingBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemStaking

struct UnstakingBalanceProvider {
    private let tokenItem: TokenItem
    private let action: StakingAction
    private let balanceFormatter = BalanceFormatter()

    init(tokenItem: TokenItem, action: StakingAction) {
        self.tokenItem = tokenItem
        self.action = action
    }

    private func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let currencyCode = tokenItem.currencySymbol
        let builder = FormattedTokenBalanceTypeBuilder(format: { [balanceFormatter] value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: currencyCode)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}

// MARK: - TokenBalanceProvider

extension UnstakingBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        .loaded(action.amount)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        .just(output: balanceType)
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        mapToFormattedTokenBalanceType(type: balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        .just(output: formattedBalanceType)
    }
}
