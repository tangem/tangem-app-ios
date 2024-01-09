//
//  MainHeaderBalanceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> NSAttributedString
}

struct CommonMainHeaderBalanceFormatter: MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> NSAttributedString {
        let balanceFormatter = BalanceFormatter()
        let formattedBalance = balanceFormatter.formatFiatBalance(balance)
        return balanceFormatter.formatTotalBalanceForMain(fiatBalance: formattedBalance, formattingOptions: .defaultOptions)
    }
}

struct VisaMainHeaderBalanceFormatter: MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> NSAttributedString {
        let balanceFormatter = BalanceFormatter()
        guard let balance else {
            return balanceFormatter.formatTotalBalanceForMain(fiatBalance: BalanceFormatter.defaultEmptyBalanceString, formattingOptions: .defaultOptions)
        }
        let formattedBalance = balanceFormatter.formatCryptoBalance(balance, currencyCode: currencyCode)
        return balanceFormatter.formatTotalBalanceForMain(fiatBalance: formattedBalance, formattingOptions: .defaultOptions)
    }
}
