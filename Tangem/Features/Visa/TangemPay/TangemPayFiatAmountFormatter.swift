//
//  TangemPayFiatAmountFormatter.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// The single place where Tangem Pay fiat amounts (card spends, refunds, deposits, fees, cashback) are turned into text.
///
/// Digits, grouping and the sign always follow `en_US` (`-$1,234.50`), so every Tangem Pay screen shows the same
/// shape regardless of the device locale. Only the currency symbol is localized (`$`, `US$`, `€`), falling back to
/// the `en_US` symbol and finally to the raw currency code.
struct TangemPayFiatAmountFormatter {
    private static let baseLocale = Locale(identifier: "en_US")

    private let locale: Locale

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = TangemPayFiatAmountFormatter.baseLocale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// - Parameter locale: The locale used to pick the currency symbol. Digits and separators are not affected by it.
    init(locale: Locale = .current) {
        self.locale = locale
    }

    func format(_ amount: Decimal, currencyCode: String, hidesFractionForWholeAmounts: Bool = false) -> String {
        let currencyCode = currencyCode.uppercased()
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = symbol(forCurrencyCode: currencyCode)
        formatter.minimumFractionDigits = hidesFractionForWholeAmounts && Self.isWhole(amount) ? 0 : 2

        return formatter.format(number: amount)
    }

    /// Same as `format(_:currencyCode:)`, but a positive amount gets an explicit plus sign (`+$12.30`).
    /// Negative amounts keep the regular minus sign (`-$12.30`), zero has no sign.
    func formatSigned(_ amount: Decimal, currencyCode: String) -> String {
        let prefix: String = amount > 0 ? .plusSign : .empty
        return prefix + format(amount, currencyCode: currencyCode)
    }

    private static func isWhole(_ amount: Decimal) -> Bool {
        amount == amount.rounded(scale: 0, roundingMode: .plain)
    }

    private func symbol(forCurrencyCode currencyCode: String) -> String {
        locale.localizedCurrencySymbol(forCurrencyCode: currencyCode)
            ?? Self.baseLocale.localizedCurrencySymbol(forCurrencyCode: currencyCode)
            ?? currencyCode
    }
}
