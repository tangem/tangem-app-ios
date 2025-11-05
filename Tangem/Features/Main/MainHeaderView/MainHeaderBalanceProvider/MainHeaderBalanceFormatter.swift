//
//  MainHeaderBalanceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> AttributedString
}

extension MainHeaderBalanceFormatter {
    /// The `currencyCode` is  `AppSettings.shared.selectedCurrencyCode`
    func formatBalance(balance: Decimal?) -> AttributedString {
        formatBalance(balance: balance, currencyCode: AppSettings.shared.selectedCurrencyCode)
    }
}

// MARK: - Crypto

struct CommonMainHeaderBalanceFormatter: MainHeaderBalanceFormatter {
    let balanceFormatter = BalanceFormatter()

    func formatBalance(balance: Decimal?, currencyCode: String) -> AttributedString {
        let formattedBalance = balanceFormatter.formatFiatBalance(balance)
        return balanceFormatter.formatAttributedTotalBalance(fiatBalance: formattedBalance, formattingOptions: .defaultOptions)
    }
}
