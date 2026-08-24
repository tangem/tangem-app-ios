//
//  TangemPayFiatAmountFormatter.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TangemPayFiatAmountFormatter {
    private static let baseLocale = Locale(identifier: "en_US")

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = TangemPayFiatAmountFormatter.baseLocale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    func format(_ amount: Decimal, currencyCode: String, hidesFractionForWholeAmounts: Bool = false) -> String {
        let currencyCode = currencyCode.uppercased()
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = Self.symbol(forCurrencyCode: currencyCode)
        formatter.minimumFractionDigits = hidesFractionForWholeAmounts && Self.isWhole(amount) ? 0 : 2

        return formatter.format(number: amount)
    }

    private static func isWhole(_ amount: Decimal) -> Bool {
        amount == amount.rounded(scale: 0, roundingMode: .plain)
    }

    private static func symbol(forCurrencyCode currencyCode: String) -> String {
        Locale.current.localizedCurrencySymbol(forCurrencyCode: currencyCode)
            ?? baseLocale.localizedCurrencySymbol(forCurrencyCode: currencyCode)
            ?? currencyCode
    }
}
