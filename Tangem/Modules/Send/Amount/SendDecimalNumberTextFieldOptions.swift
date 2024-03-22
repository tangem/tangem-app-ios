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
    private let cryptoCurrencySymbol: String
    private let fiatCurrencyCode: String

    init(cryptoCurrencySymbol: String, fiatCurrencyCode: String) {
        self.cryptoCurrencySymbol = cryptoCurrencySymbol
        self.fiatCurrencyCode = fiatCurrencyCode
    }

    func makeCryptoOptions() -> SendDecimalNumberTextFieldOptions {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = cryptoCurrencySymbol

        return options(from: numberFormatter, currency: cryptoCurrencySymbol, forceSpace: true)
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
