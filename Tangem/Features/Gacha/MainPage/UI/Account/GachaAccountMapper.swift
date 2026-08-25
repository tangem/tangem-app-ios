//
//  GachaAccountMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum GachaAccountMapper {
    private static let balanceFormatter = BalanceFormatter()

    static func map(_ summary: GachaAccountSummary) -> GachaAccountView.Summary {
        GachaAccountView.Summary(
            fiatBalanceText: balanceFormatter.formatFiatBalance(
                summary.fiatBalance,
                currencyCode: summary.fiatCurrencyCode
            ),
            cryptoBalanceText: balanceFormatter.formatCryptoBalance(
                summary.cryptoBalance,
                currencyCode: summary.cryptoCurrencyCode
            ),
            // [REDACTED_TODO_COMMENT]
            collectionCountText: "\(summary.collectionCardsCount) cards"
        )
    }
}
