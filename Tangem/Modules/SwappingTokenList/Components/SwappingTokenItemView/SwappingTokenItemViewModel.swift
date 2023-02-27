//
//  SwappingTokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SwappingTokenItemViewModel: Identifiable {
    var id: Int { hashValue }

    // ViewState
    let tokenId: String
    let iconURL: URL?
    let name: String
    let symbol: String
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
        tokenId: String,
        iconURL: URL? = nil,
        name: String,
        symbol: String,
        balance: CurrencyAmount?,
        fiatBalance: Decimal?,
        itemDidTap: @escaping () -> Void
    ) {
        self.tokenId = tokenId
        self.iconURL = iconURL
        self.name = name
        self.symbol = symbol
        self.balance = balance
        self.fiatBalance = fiatBalance
        self.itemDidTap = itemDidTap
    }
}

extension SwappingTokenItemViewModel: Hashable {
    static func == (lhs: SwappingTokenItemViewModel, rhs: SwappingTokenItemViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tokenId)
        hasher.combine(iconURL)
        hasher.combine(name)
        hasher.combine(symbol)
        hasher.combine(balance)
        hasher.combine(fiatBalance)
    }
}
