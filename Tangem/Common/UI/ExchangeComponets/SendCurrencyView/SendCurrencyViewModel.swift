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
    private(set) var isLockedVisible: Bool
    private(set) var maximumFractionDigits: Int

    let tokenIcon: SwappingTokenIconViewModel

    var balanceString: String {
        Localization.commonBalance(balance.groupedFormatted())
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
        fiatValue: Decimal,
        isLockedVisible: Bool = false,
        tokenIcon: SwappingTokenIconViewModel
    ) {
        self.balance = balance
        self.maximumFractionDigits = maximumFractionDigits
        self.fiatValue = fiatValue
        self.isLockedVisible = isLockedVisible
        self.tokenIcon = tokenIcon
    }

    mutating func update(fiatValue: Decimal) {
        self.fiatValue = fiatValue
    }

    mutating func update(maximumFractionDigits: Int) {
        self.maximumFractionDigits = maximumFractionDigits
    }

    mutating func update(isLockedVisible: Bool) {
        self.isLockedVisible = isLockedVisible
    }
}

extension SendCurrencyViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(balance)
        hasher.combine(fiatValue)
        hasher.combine(tokenIcon)
    }
}
