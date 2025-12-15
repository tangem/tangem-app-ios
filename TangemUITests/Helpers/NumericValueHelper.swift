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
        let cleanedText = text
            .replacingOccurrences(of: "[$₽€£¥]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        if let number = formatter.number(from: cleanedText) {
            return number.decimalValue
        }

        XCTFail("Failed to parse text '\(text)' as Decimal")
        return Decimal(0)
    }
}
