//
//  SendDecimalNumberTextFieldOptions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendDecimalNumberTextFieldOptions {
    let prefix: String?
    let hasSpaceAfterPrefix: Bool

    let hasSpaceBeforeSuffix: Bool
    let suffix: String?
}

struct SendDecimalNumberTextFieldOptionsFactory {
    private let cryptoCurrencyCode: String
    private let fiatCurrencyCode: String

    init(cryptoCurrencyCode: String, fiatCurrencyCode: String) {
        self.cryptoCurrencyCode = cryptoCurrencyCode
        self.fiatCurrencyCode = fiatCurrencyCode
    }

    func makeCryptoOptions() -> SendDecimalNumberTextFieldOptions {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = cryptoCurrencyCode

        return options(from: numberFormatter, currency: cryptoCurrencyCode, forceSpace: true)
    }

    func makeFiatOptions() -> SendDecimalNumberTextFieldOptions {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = fiatCurrencyCode

        let localizedCurrencySymbol = Locale.current.localizedCurrencySymbol(forCurrencyCode: fiatCurrencyCode) ?? fiatCurrencyCode
        return options(from: numberFormatter, currency: localizedCurrencySymbol, forceSpace: false)
    }

    private func options(from numberFormatter: NumberFormatter, currency: String, forceSpace: Bool) -> SendDecimalNumberTextFieldOptions {
        let format = numberFormatter.positiveFormat ?? ""
        let currencySymbolPlaceholder: Character = "¤"

        let hasPrefix = (format.first == currencySymbolPlaceholder)

        let hasSpaceAfterPrefix: Bool
        let hasSpaceBeforeSuffix: Bool
        if forceSpace {
            hasSpaceAfterPrefix = true
            hasSpaceBeforeSuffix = true
        } else {
            hasSpaceAfterPrefix = format.dropFirst().first?.isWhitespace ?? false
            hasSpaceBeforeSuffix = format.dropLast().last?.isWhitespace ?? false
        }

        return SendDecimalNumberTextFieldOptions(
            prefix: hasPrefix ? currency : nil,
            hasSpaceAfterPrefix: hasSpaceAfterPrefix,
            hasSpaceBeforeSuffix: hasSpaceBeforeSuffix,
            suffix: hasPrefix ? nil : currency
        )
    }
}
