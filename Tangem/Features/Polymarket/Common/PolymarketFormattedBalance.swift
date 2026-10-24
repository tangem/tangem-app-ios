//
//  PolymarketFormattedBalance.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum PolymarketFormattedBalance {
    static func money(_ balanceType: TokenBalanceType) -> FormattedTokenBalanceType {
        switch balanceType {
        case .empty:
            return .failure(.empty(BalanceFormatter.defaultEmptyBalanceString))
        case .loading, .failure, .loaded:
            let builder = FormattedTokenBalanceTypeBuilder(format: PolymarketOrderFormatter.money)

            return builder.mapToFormattedTokenBalanceType(type: balanceType)
        }
    }
}

// MARK: - Total balance

extension PolymarketAccountModel {
    var formattedTotalBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        collateralTotalBalanceProvider
            .balanceTypePublisher
            .map(PolymarketFormattedBalance.money)
            .eraseToAnyPublisher()
    }
}
