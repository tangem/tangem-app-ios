//
//  SendCryptoValueFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Formatter that can work around NumberFormatter's limitations on Decimal numbers with currency
struct SendCryptoValueFormatter {
    private let decimalNumberFormatter: DecimalNumberFormatter
    private let prefixSuffixOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    private let trimFractions: Bool
    private let locale: Locale

    init(decimals: Int, currencySymbol: String, trimFractions: Bool, locale: Locale = .current) {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale

        decimalNumberFormatter = DecimalNumberFormatter(numberFormatter: numberFormatter, maximumFractionDigits: decimals)

        let optionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory(locale: locale)
        prefixSuffixOptions = optionsFactory.makeCryptoOptions(cryptoCurrencyCode: currencySymbol)

        self.trimFractions = trimFractions
        self.locale = locale
    }

    func string(from value: Decimal) -> String {
        string(from: value, prefixSuffixOptions: prefixSuffixOptions)
    }

    func string(
        from value: Decimal,
        prefixSuffixOptions: SendDecimalNumberTextField.PrefixSuffixOptions?
    ) -> String {
        let formatterInput = formatterInput(from: value)
        let formattedAmount = decimalNumberFormatter.format(value: formatterInput)
        let nbsp = AppConstants.unbreakableSpace

        switch prefixSuffixOptions {
        case .none:
            return formattedAmount
        case .prefix(.some(let text), let hasSpace):
            return text + (hasSpace ? nbsp : "") + formattedAmount
        case .suffix(.some(let text), let hasSpace):
            return formattedAmount + (hasSpace ? nbsp : "") + text
        default:
            return formattedAmount
        }
    }

    private func formatterInput(from value: Decimal) -> String {
        let fractionAfter2Digits: Decimal = (value * 100 - (value * 100).rounded())
        let canBeTrimmed = fractionAfter2Digits.isZero

        if canBeTrimmed {
            let basicFormatter = NumberFormatter()
            basicFormatter.locale = locale
            basicFormatter.minimumFractionDigits = trimFractions ? 0 : 2
            basicFormatter.maximumFractionDigits = 2
            return basicFormatter.string(from: value as NSDecimalNumber) ?? "\(value)"
        } else {
            let stringNumber = (value as NSDecimalNumber).stringValue
            return stringNumber.replacingOccurrences(of: ".", with: String(decimalNumberFormatter.decimalSeparator))
        }
    }
}
