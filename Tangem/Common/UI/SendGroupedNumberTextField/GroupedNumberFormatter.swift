//
//  GroupedNumberFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct GroupedNumberFormatter {
    var maximumFractionDigits: Int { numberFormatter.maximumFractionDigits }
    var decimalSeparator: Character { Character(numberFormatter.decimalSeparator) }
    var groupingSeparator: String { numberFormatter.groupingSeparator }

    private let numberFormatter: NumberFormatter

    init(
        numberFormatter: NumberFormatter = NumberFormatter(),
        maximumFractionDigits: Int
    ) {
        self.numberFormatter = numberFormatter

        numberFormatter.roundingMode = .down
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0 // Just for case
        numberFormatter.maximumFractionDigits = maximumFractionDigits
    }

    mutating func update(maximumFractionDigits: Int) {
        numberFormatter.maximumFractionDigits = maximumFractionDigits
    }

    func format(from string: String) -> String {
        // Exclude unnecessary logic
        guard !string.isEmpty else { return "" }

        // If string contains decimalSeparator will format it separately
        if string.contains(decimalSeparator) {
            return formatIntegerAndFractionSeparately(string: string)
        }

        // Remove space separators for formatter correct work
        let numberString = string.replacingOccurrences(of: " ", with: "")

        // If textFieldText is correct number, return formatted number
        if let value = numberFormatter.number(from: numberString) {
            // numberFormatter.string use ONLY for integer values
            // without decimals because formatter reduce fractions to 13 symbols
            return numberFormatter.string(for: value.decimalValue) ?? ""
        }

        // Otherwise just return text
        return string
    }

    func format(from value: Decimal) -> String {
        let stringNumber = value.description.replacingOccurrences(of: ".", with: String(decimalSeparator))
        return format(from: stringNumber)
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

        guard let bodyNumber = numberFormatter.number(from: beforeComma) else {
            return string
        }

        // Check to maximumFractionDigits and reduce it if needed
        let maximumWithComma = maximumFractionDigits + 1
        if afterComma.count > maximumWithComma {
            let lastAcceptableIndex = afterComma.index(afterComma.startIndex, offsetBy: maximumFractionDigits)
            afterComma = afterComma[afterComma.startIndex ... lastAcceptableIndex]
        }

        return format(from: bodyNumber.decimalValue) + afterComma
    }
}
