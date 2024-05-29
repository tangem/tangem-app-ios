//
//  SendCryptoValueFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Formatter that can work around NumberFormatter's limitations on Decimal numbers with currency
struct SendCryptoValueFormatter {
    private let decimalNumberFormatter: DecimalNumberFormatter
    private let preffixSuffixOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    private let trimFractions: Bool

    init(decimals: Int, currencySymbol: String, trimFractions: Bool, locale: Locale = .current) {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale

        decimalNumberFormatter = DecimalNumberFormatter(numberFormatter: numberFormatter, maximumFractionDigits: decimals)

        let optionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory(
            cryptoCurrencyCode: currencySymbol,
            fiatCurrencyCode: "",
            locale: locale
        )
        preffixSuffixOptions = optionsFactory.makeCryptoOptions()

        self.trimFractions = trimFractions
    }

    func string(from value: Decimal) -> String? {
        guard let formatterInput = formatterInput(from: value) else { return nil }

        let formattedAmount = decimalNumberFormatter.format(value: formatterInput)
        let nbsp = AppConstants.unbreakableSpace

        switch preffixSuffixOptions {
        case .prefix(let text, let hasSpace):
            guard let text else { return nil }
            return text + (hasSpace ? nbsp : "") + formattedAmount
        case .suffix(let text, let hasSpace):
            guard let text else { return nil }
            return formattedAmount + (hasSpace ? nbsp : "") + text
        }
    }

    private func formatterInput(from value: Decimal) -> String? {
        let fractionAfter2Digits: Decimal = (value * 100 - (value * 100).rounded())
        let canBeTrimmed = fractionAfter2Digits.isZero

        if canBeTrimmed {
            let basicFormatter = NumberFormatter()
            basicFormatter.locale = Locale(identifier: "en_US")
            basicFormatter.minimumFractionDigits = trimFractions ? 0 : 2
            basicFormatter.maximumFractionDigits = 2
            return basicFormatter.string(from: value as NSDecimalNumber)
        } else {
            return (value as NSDecimalNumber).stringValue
        }
    }
}
