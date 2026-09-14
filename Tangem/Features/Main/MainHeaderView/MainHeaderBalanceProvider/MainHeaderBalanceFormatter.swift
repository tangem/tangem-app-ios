//
//  MainHeaderBalanceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MainHeaderBalanceFormatter {
    let balanceFormatter = BalanceFormatter()

    func formatBalance(balance: Decimal?, currencyCode: String) -> AttributedString {
        let formattedBalance = balanceFormatter.formatFiatBalance(balance, currencyCode: currencyCode)
        let formattingOptions: TotalBalanceFormattingOptions = .mainHeaderRedesign

        return balanceFormatter.formatAttributedTotalBalance(fiatBalance: formattedBalance, formattingOptions: formattingOptions)
    }
}
