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

    func formatBalance(balance: Decimal?, currencyCode: String = AppSettings.shared.selectedCurrencyCode) -> AttributedString {
        let formattedBalance = balanceFormatter.formatFiatBalance(balance)
        let formattingOptions: TotalBalanceFormattingOptions = FeatureProvider.isAvailable(.redesign)
            ? .defaultOptionsRedesign
            : .defaultOptions

        return balanceFormatter.formatAttributedTotalBalance(fiatBalance: formattedBalance, formattingOptions: formattingOptions)
    }
}
