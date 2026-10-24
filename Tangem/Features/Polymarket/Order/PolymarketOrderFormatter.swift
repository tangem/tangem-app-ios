//
//  PolymarketOrderFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

enum PolymarketOrderFormatter {
    /// The collateral trades one to one with the dollar, so its amounts are drawn with the dollar sign and
    /// are never converted into the currency the app is set to.
    static func money(_ value: Decimal?) -> String {
        formatter.formatFiatBalance(value, currencyCode: Constants.currencyCode)
    }

    static func enteredAmount(_ value: Decimal?) -> String {
        formatter.formatFiatBalance(value, currencyCode: Constants.currencyCode, formattingOptions: .enteredAmount)
    }

    static func shares(_ value: Decimal?) -> String {
        formatter.formatDecimal(value, formattingOptions: .shares)
    }

    static func displayedMoney(_ value: Decimal) -> Decimal {
        value.rounded(scale: Constants.moneyScale, roundingMode: .plain)
    }

    static func signedMoney(_ value: Decimal) -> String {
        let displayed = displayedMoney(value)

        guard displayed != 0 else { return money(0) }

        let sign = displayed < 0 ? String.minusSign : String.plusSign

        return "\(sign) \(money(abs(displayed)))"
    }

    private static let formatter = BalanceFormatter()
}

// MARK: - Constants

private extension PolymarketOrderFormatter {
    enum Constants {
        static let currencyCode = "USD"
        static let moneyScale = 2
    }
}

// MARK: - Formatting options

private extension BalanceFormattingOptions {
    static let enteredAmount = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: 2,
        formatEpsilonAsLowestRepresentableValue: true,
        roundingType: .default(roundingMode: .plain, scale: 2)
    )

    static let shares = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: 2,
        formatEpsilonAsLowestRepresentableValue: false,
        roundingType: .default(roundingMode: .down, scale: 2)
    )
}
