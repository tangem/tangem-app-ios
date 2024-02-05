//
//  MainHeaderBalanceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> AttributedStringParameters
}

struct CommonMainHeaderBalanceFormatter: MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> AttributedStringParameters {
        let balanceFormatter = BalanceFormatter()
        let formattedBalance = balanceFormatter.formatFiatBalance(balance)
        return balanceFormatter.formatAttributedTotalBalance(fiatBalance: formattedBalance, formattingOptions: .defaultOptions)
    }
}

struct VisaMainHeaderBalanceFormatter: MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> AttributedStringParameters {
        let balanceFormatter = BalanceFormatter()
        guard let balance else {
            return balanceFormatter.formatAttributedTotalBalance(fiatBalance: BalanceFormatter.defaultEmptyBalanceString, formattingOptions: .defaultOptions)
        }
        let formattedBalance = balanceFormatter.formatCryptoBalance(balance, currencyCode: currencyCode)
        return balanceFormatter.formatAttributedTotalBalance(fiatBalance: formattedBalance, formattingOptions: .defaultOptions)
    }
}
