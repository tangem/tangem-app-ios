//
//  NumericValueHelper.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

enum NumericValueHelper {
    static func parseNumericValue(from text: String) -> Decimal {
        // Handle dash symbol (indicates no value/error state)
        if text.contains("–") {
            XCTFail("Balance should have numeric value instead of dash")
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current

        // Parsing with original text first
        if let number = formatter.number(from: text) {
            return number.decimalValue
        }

        // If that fails, try removing common currency symbols and parsing again
        var cleanedText =
            text
                .replacingOccurrences(of: "[$₽€£¥]", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

        // Handle suffixes
        let multipliers: [String: Decimal] = ["K": 1_000, "M": 1_000_000, "B": 1_000_000_000]
        var multiplier: Decimal = 1

        for (suffix, value) in multipliers {
            if cleanedText.hasSuffix(suffix) {
                multiplier = value
                cleanedText = String(cleanedText.dropLast(suffix.count)).trimmingCharacters(
                    in: .whitespaces)
                break
            }
        }

        if let number = formatter.number(from: cleanedText) {
            return number.decimalValue * multiplier
        }

        XCTFail("Failed to parse text '\(text)' as Decimal")
        return Decimal(0)
    }
}
