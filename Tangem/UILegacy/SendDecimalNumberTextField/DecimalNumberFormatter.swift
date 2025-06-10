//
//  DecimalNumberFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
struct DecimalNumberFormatter {
    public var isDecimal: Bool { numberFormatter.maximumFractionDigits > 0 }
    public var decimalSeparator: Character { Character(numberFormatter.decimalSeparator) }

    private let numberFormatter: NumberFormatter

    init(
        numberFormatter: NumberFormatter = .init(),
        maximumFractionDigits: Int
    ) {
        self.numberFormatter = numberFormatter

        numberFormatter.roundingMode = .down
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0 // Just for case
        numberFormatter.maximumFractionDigits = maximumFractionDigits
    }

    func update(maximumFractionDigits: Int) {
        numberFormatter.maximumFractionDigits = maximumFractionDigits
    }

    // MARK: - Formatted

    public func format(value: String) -> String {
        // Exclude unnecessary logic
        guard !value.isEmpty else {
            return ""
        }

        let (beforeComma, afterComma) = separateStringByDecimalSeparator(string: value)

        if isDecimal {
            return formatInteger(value: beforeComma) + afterComma
        }

        return formatInteger(value: beforeComma)
    }

    public func format(value: Decimal) -> String {
        return format(value: mapToString(decimal: value))
    }

    public func format(value: Decimal) -> Decimal? {
        mapToDecimal(string: format(value: mapToString(decimal: value)))
    }

    // MARK: - Mapping

    public func mapToString(decimal: Decimal) -> String {
        let stringNumber = (decimal as NSDecimalNumber).stringValue
        return stringNumber.replacingOccurrences(of: ".", with: String(decimalSeparator))
    }

    public func mapToDecimal(string: String) -> Decimal? {
        if string.isEmpty {
            return nil
        }

        // Convert formatted string to correct decimal number
        let formattedValue = string
            .replacingOccurrences(of: String(numberFormatter.groupingSeparator), with: "")
            .replacingOccurrences(of: String(decimalSeparator), with: ".")

        // We can't use here the NumberFormatter because it work with the NSNumber
        // And NSNumber is working wrong with ten zeros and one after decimalSeparator
        // Eg. NumberFormatter.number(from: "0.00000000001") will return "0.000000000009999999999999999"
        // Like is NSNumber(floatLiteral: 0.00000000001) will return "0.000000000009999999999999999"
        if let value = Decimal(string: formattedValue) {
            return value
        }

        assertionFailure("String isn't a correct Number")
        return .zero
    }
}

// MARK: - Private

private extension DecimalNumberFormatter {
    func separateStringByDecimalSeparator(string: String) -> (beforeComma: String, afterComma: String) {
        guard let commaIndex = string.firstIndex(of: decimalSeparator) else {
            return (beforeComma: string, afterComma: "")
        }

        let beforeComma = String(string[string.startIndex ..< commaIndex])
        var afterComma = string[commaIndex ..< string.endIndex]
        let maximumFractionDigits = numberFormatter.maximumFractionDigits

        // Check to maximumFractionDigits and reduce if needed
        let maximumWithComma = maximumFractionDigits + 1
        if afterComma.count > maximumWithComma {
            let lastAcceptableIndex = afterComma.index(afterComma.startIndex, offsetBy: maximumFractionDigits)
            afterComma = afterComma[afterComma.startIndex ... lastAcceptableIndex]
        }

        return (beforeComma: beforeComma, afterComma: String(afterComma))
    }

    /// In this case the NumberFormatter works fine ONLY with integer values
    /// We can't trust it because it reduces fractions to 13 characters
    private func formatInteger(value: String) -> String {
        assert(!value.contains(decimalSeparator))

        if let decimal = mapToDecimal(string: value) {
            return numberFormatter.string(from: decimal as NSDecimalNumber) ?? ""
        }

        return value
    }
}
