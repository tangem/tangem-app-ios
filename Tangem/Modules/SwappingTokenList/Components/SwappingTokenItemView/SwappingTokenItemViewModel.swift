//
//  SwappingTokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SwappingTokenItemViewModel: Identifiable {
    let id: String
    let iconURL: URL?
    let name: String
    let symbol: String
    let fiatBalance: Decimal?
    let balance: Decimal?
    let itemDidTap: () -> Void

    var fiatBalanceFormatted: String? {
        fiatBalance?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    var balanceFormatted: String? {
        balance?.groupedFormatted()
    }

    init(
        id: String,
        iconURL: URL? = nil,
        name: String,
        symbol: String,
        fiatBalance: Decimal?,
        balance: Decimal?,
        itemDidTap: @escaping () -> Void
    ) {
        self.id = id
        self.iconURL = iconURL
        self.name = name
        self.symbol = symbol
        self.fiatBalance = fiatBalance
        self.balance = balance
        self.itemDidTap = itemDidTap
    }
}
