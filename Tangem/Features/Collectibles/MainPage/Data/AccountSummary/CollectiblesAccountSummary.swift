//
//  CollectiblesAccountSummary.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CollectiblesAccountSummary {
    let fiatBalance: Decimal
    let fiatCurrencyCode: String
    let cryptoBalance: Decimal
    let cryptoCurrencyCode: String
    let collectionCardsCount: Int
}
