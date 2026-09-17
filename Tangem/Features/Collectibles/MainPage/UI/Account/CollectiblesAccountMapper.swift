//
//  CollectiblesAccountMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum CollectiblesAccountMapper {
    private static let balanceFormatter = BalanceFormatter()

    static func map(_ summary: CollectiblesAccountSummary) -> CollectiblesAccountView.Summary {
        CollectiblesAccountView.Summary(
            fiatBalanceText: balanceFormatter.formatFiatBalance(
                summary.fiatBalance,
                currencyCode: summary.fiatCurrencyCode
            ),
            cryptoBalanceText: balanceFormatter.formatCryptoBalance(
                summary.cryptoBalance,
                currencyCode: summary.cryptoCurrencyCode
            ),
            collectionCountText: Localization.collectiblesAccountCollectionCardsCount(summary.collectionCardsCount)
        )
    }
}
