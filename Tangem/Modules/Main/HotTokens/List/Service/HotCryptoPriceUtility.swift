//
//  HotCryptoPriceUtility.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class HotCryptoPriceUtility {
    private let balanceFormatter = BalanceFormatter()
    private let priceChangeUtility = PriceChangeUtility()

    func formatFiatPrice(_ price: Decimal) -> String {
        balanceFormatter.formatFiatBalance(price, currencyCode: AppSettings.shared.selectedCurrencyCode)
    }

    func convertToPriceChangeState(from value: Decimal) -> TokenPriceChangeView.State {
        priceChangeUtility.convertToPriceChangeState(changePercent: value)
    }
}
