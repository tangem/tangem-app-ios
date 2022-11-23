//
//  SendCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SendCurrencyViewModel: Identifiable {
    var id: Int { hashValue }
    let tokenIcon: TokenIconViewModel

    var tokenName: String { tokenIcon.name }

    var balanceString: String {
        "common_balance".localized(balance.groupedFormatted())
    }

    var fiatValueString: String {
        fiatValue.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    private let balance: Decimal
    private(set) var maximumFractionDigits: Int
    private var fiatValue: Decimal

    init(
        balance: Decimal,
        maximumFractionDigits: Int,
        fiatValue: Decimal,
        tokenIcon: TokenIconViewModel
    ) {
        self.balance = balance
        self.maximumFractionDigits = maximumFractionDigits
        self.fiatValue = fiatValue
        self.tokenIcon = tokenIcon
    }

    mutating func update(fiatValue: Decimal) {
        self.fiatValue = fiatValue
    }

    mutating func update(maximumFractionDigits: Int) {
        self.maximumFractionDigits = maximumFractionDigits
    }
}

extension SendCurrencyViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(balance)
        hasher.combine(fiatValue)
        hasher.combine(tokenIcon)
    }
}
