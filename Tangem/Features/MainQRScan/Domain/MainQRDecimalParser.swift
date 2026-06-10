//
//  MainQRDecimalParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum MainQRDecimalParser {
    static func parseDecimal(_ string: String) -> Decimal? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let decimalSeparator = Locale.posixEnUS.decimalSeparator ?? "."
        let normalized = normalizeDecimalSeparators(in: trimmed, decimalSeparator: decimalSeparator)

        guard isStrictDecimalString(normalized, decimalSeparator: decimalSeparator) else {
            return nil
        }

        return Decimal(stringValue: normalized)
    }

    private static func normalizeDecimalSeparators(in string: String, decimalSeparator: String) -> String {
        string.replacingOccurrences(of: ",", with: decimalSeparator)
    }

    private static func isStrictDecimalString(_ string: String, decimalSeparator: String) -> Bool {
        let escapedSeparator = NSRegularExpression.escapedPattern(for: decimalSeparator)
        let pattern = "^[+-]?(?:\\d+(?:\(escapedSeparator)\\d+)?|\(escapedSeparator)\\d+)(?:[eE][+-]?\\d+)?$"
        return string.range(of: pattern, options: .regularExpression) != nil
    }
}
