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

    // ViewState
    private(set) var maximumFractionDigits: Int
    private(set) var isChangeable: Bool

    let tokenIcon: SwappingTokenIconViewModel

    var balanceString: String {
        Localization.commonBalance(balance.groupedFormatted(maximumFractionDigits: maximumFractionDigits))
    }

    var fiatValueString: String {
        fiatValue.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    // Private
    private let balance: Decimal
    private var fiatValue: Decimal

    init(
        balance: Decimal,
        maximumFractionDigits: Int,
        isChangeable: Bool,
        fiatValue: Decimal,
        tokenIcon: SwappingTokenIconViewModel
    ) {
        self.balance = balance
        self.maximumFractionDigits = maximumFractionDigits
        self.isChangeable = isChangeable
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
        hasher.combine(maximumFractionDigits)
        hasher.combine(isChangeable)
    }
}
