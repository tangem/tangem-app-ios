//
//  ExpressTokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressTokenItemViewModel: Identifiable {
    let id: String
    let tokenIconItem: TokenIconItemViewModel
    let name: String
    let symbol: String
    let isDisable: Bool
    let itemDidTap: () -> Void

    var balanceFormatted: String? {
        balance?.formatted
    }

    var fiatBalanceFormatted: String? {
        fiatBalance?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    // Private
    private let balance: CurrencyAmount?
    private let fiatBalance: Decimal?

    init(
        id: String,
        tokenIconItem: TokenIconItemViewModel,
        name: String,
        symbol: String,
        balance: CurrencyAmount?,
        fiatBalance: Decimal?,
        isDisable: Bool,
        itemDidTap: @escaping () -> Void
    ) {
        self.id = id
        self.tokenIconItem = tokenIconItem
        self.name = name
        self.symbol = symbol
        self.balance = balance
        self.fiatBalance = fiatBalance
        self.isDisable = isDisable
        self.itemDidTap = itemDidTap
    }
}
