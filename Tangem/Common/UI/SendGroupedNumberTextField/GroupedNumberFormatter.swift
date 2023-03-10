//
//  GroupedNumberFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// Format
// 1. String to String for text field
//  1.1 Int decimal
//  1.1
// 2. String to Decimal for send value
// 3. Decimal to String for external update
struct GroupedNumberFormatter {
    public let roundingMode: NSDecimalNumber.RoundingMode
    public var maximumFractionDigits: Int { numberFormatter.maximumFractionDigits }
    public var decimalSeparator: Character { Character(numberFormatter.decimalSeparator) }
    public var groupingSeparator: Character { Character(numberFormatter.groupingSeparator) }

    private let numberFormatter: NumberFormatter

    init(
        numberFormatter: NumberFormatter = NumberFormatter(),
        maximumFractionDigits: Int,
        roundingMode: NSDecimalNumber.RoundingMode = .down
    ) {
        self.numberFormatter = numberFormatter
        self.roundingMode = roundingMode

        numberFormatter.roundingMode = .down
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0 // Just for case
        numberFormatter.maximumFractionDigits = maximumFractionDigits
    }

    mutating func update(maximumFractionDigits: Int) {
        numberFormatter.maximumFractionDigits = maximumFractionDigits
    }

    // MARK: - Formatted

    public func format(value: String) -> String {
        // Exclude unnecessary logic
        guard !value.isEmpty else {
            return ""
        }

        guard var decimal = mapToDecimal(string: value) else {
            assertionFailure("Value must be number")
            return value
        }

        // Round to maximumFractionDigits
        decimal.round(scale: maximumFractionDigits, roundingMode: roundingMode)

        // If string contains decimalSeparator will format it separately
        if value.contains(decimalSeparator) {
            return formatIntegerAndFractionSeparately(string: value)
        }

        return formatInteger(decimal: decimal)
    }

    public func format(value: Decimal) -> String {
        return format(value: mapToString(decimal: value))
    }

    // MARK: - Mapping

    public func mapToString(decimal: Decimal) -> String {
        var stringNumber = (decimal as NSDecimalNumber).stringValue
        return stringNumber.replacingOccurrences(of: ".", with: String(decimalSeparator))
    }

    public func mapToDecimal(string: String) -> Decimal? {
        var formattedValue = string

        // Convert formatted string to correct decimal number
        formattedValue = formattedValue.replacingOccurrences(of: String(groupingSeparator), with: "")
        formattedValue = formattedValue.replacingOccurrences(of: String(decimalSeparator), with: ".")

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

private extension GroupedNumberFormatter {
    func formatIntegerAndFractionSeparately(string: String) -> String {
        guard let commaIndex = string.firstIndex(of: decimalSeparator) else {
            return string
        }

        let beforeComma = String(string[string.startIndex ..< commaIndex])
        var afterComma = string[commaIndex ..< string.endIndex]

        // Check to maximumFractionDigits and reduce it if needed
        let maximumWithComma = maximumFractionDigits + 1
        if afterComma.count > maximumWithComma {
            let lastAcceptableIndex = afterComma.index(afterComma.startIndex, offsetBy: maximumFractionDigits)
            afterComma = afterComma[afterComma.startIndex ... lastAcceptableIndex]
        }

        return format(value: beforeComma) + afterComma
    }

    private func formatInteger(decimal: Decimal) -> String {
        let string = mapToString(decimal: decimal)

        // In this case the NumberFormatter works fine ONLY with integer values
        // We can't trust it because it reduces fractions to 13 characters
        assert(!string.contains(decimalSeparator))

        return numberFormatter.string(from: decimal as NSDecimalNumber) ?? ""
    }
}
