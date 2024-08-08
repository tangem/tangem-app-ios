//
//  DefaultAmountNotationFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class DefaultAmountNotationFormatter {
    private let isWithLeadingCurrencySymbol: Bool
    private let defaultEmptyValue: String = BalanceFormatter.defaultEmptyBalanceString

    init(locale: Locale = .current) {
        /// This part is used to determine if currency symbol for selected locale is placed after amount value or before.
        /// https://forums.swift.org/t/format-currency-using-a-compact-notation/69443/4
        let currencyStyle = Decimal.FormatStyle.Currency(code: "USD", locale: locale).attributed
        let formattedString = Decimal(1).formatted(currencyStyle)

        if let symbolInfo = formattedString.runs[\.numberSymbol].first(where: { $0.0 == .currency }) {
            let isTrailing = symbolInfo.1.lowerBound == formattedString.characters.startIndex
            isWithLeadingCurrencySymbol = isTrailing
        } else {
            isWithLeadingCurrencySymbol = false
        }
    }

    /// System implementation of notation suffix generation with rounding behaviour
    /// Awaiting https://developer.apple.com/documentation/foundation/decimal/formatstyle/currency/4405506-notation  for iOS18+. Currently in beta
    func format(
        _ value: Decimal?,
        precision: NumberFormatStyleConfiguration.Precision = .fractionLength(2 ... 2),
        currencySymbol: String
    ) -> String {
        guard let value else {
            return defaultEmptyValue
        }

        let baseStyle = Decimal.FormatStyle.number.precision(precision).notation(.compactName)
        let formatterAmount = value.formatted(baseStyle)
        return addCurrencySymbol(formattedAmount: formatterAmount, currencySymbol: currencySymbol)
    }

    /// Use this function when you need to use custom notation rules. E.g. values below 100k should be written fully without notation
    func format(
        _ value: Decimal?,
        notationFormatter: AmountNotationSuffixFormatter,
        numberFormatter: NumberFormatter,
        addingSignPrefix: Bool
    ) -> String {
        guard let value else {
            return defaultEmptyValue
        }

        let currencySymbol = numberFormatter.currencySymbol ?? ""
        numberFormatter.currencySymbol = ""
        let amount = notationFormatter.formatWithNotation(value)
        let intermediateFormattedAmount = (numberFormatter.string(from: abs(amount.decimal) as NSDecimalNumber) ?? "0").trimmingCharacters(in: .whitespacesAndNewlines)
        let amountWithNotation = intermediateFormattedAmount + amount.suffix
        let formattedAmount = addCurrencySymbol(formattedAmount: amountWithNotation, currencySymbol: currencySymbol)
        numberFormatter.currencySymbol = currencySymbol
        return addingSignPrefix ? amount.signPrefix + formattedAmount : formattedAmount
    }

    private func addCurrencySymbol(formattedAmount: String, currencySymbol: String) -> String {
        let separator = (currencySymbol.isEmpty || currencySymbol.count == 1) ? "" : " "
        return isWithLeadingCurrencySymbol ?
            currencySymbol + separator + formattedAmount :
            formattedAmount + " " + currencySymbol
    }
}
