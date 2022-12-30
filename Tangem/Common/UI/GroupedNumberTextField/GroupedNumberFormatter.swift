//
//  GroupedNumberFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct GroupedNumberFormatter {
    private let numberFormatter: NumberFormatter

    private var maximumFractionDigits: Int { numberFormatter.maximumFractionDigits }
    private var decimalSeparator: Character { Character(numberFormatter.decimalSeparator) }

    init(
        numberFormatter: NumberFormatter,
        maximumFractionDigits: Int = 8
    ) {
        self.numberFormatter = numberFormatter

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
            return formatNumber(value.decimalValue)
        }

        // Otherwise just return text
        return string
    }

    private func formatIntegerAndFractionSeparately(string: String) -> String {
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

        return formatNumber(bodyNumber.decimalValue) + afterComma
    }

    private func formatNumber(_ value: Decimal) -> String {
        numberFormatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
