//
//  ExpressTokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressTokenItemViewModel: Identifiable {
    let id: Int
    let tokenIconItem: TokenIconItemViewModel
    let name: String
    let symbol: String
    let balance: String
    let fiatBalance: String
    let isDisable: Bool
    let itemDidTap: () -> Void

    init(
        id: Int,
        tokenIconItem: TokenIconItemViewModel,
        name: String,
        symbol: String,
        balance: String,
        fiatBalance: String,
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
