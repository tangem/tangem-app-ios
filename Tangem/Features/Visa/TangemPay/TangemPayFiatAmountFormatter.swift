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

    func format(_ amount: Decimal, currencyCode: String) -> String {
        let currencyCode = currencyCode.uppercased()
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = Self.symbol(forCurrencyCode: currencyCode)

        return formatter.format(number: amount)
    }

    private static func symbol(forCurrencyCode currencyCode: String) -> String {
        Locale.current.localizedCurrencySymbol(forCurrencyCode: currencyCode)
            ?? baseLocale.localizedCurrencySymbol(forCurrencyCode: currencyCode)
            ?? currencyCode
    }
}
