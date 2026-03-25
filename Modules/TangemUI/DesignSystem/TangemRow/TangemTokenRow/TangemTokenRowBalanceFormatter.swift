//
//  TangemTokenRowBalanceFormatter.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public enum TangemTokenRowBalanceFormatter {
    /// Creates an `AttributedString` with different colors for integer and decimal parts.
    /// - Parameters:
    ///   - balance: The balance string to format
    ///   - font: The font to apply to the entire string
    ///   - integerColor: The color for the integer part (before decimal separator)
    ///   - decimalColor: The color for the decimal part (separator and digits after)
    /// - Returns: An `AttributedString` with the appropriate styling applied
    public static func formatWithDecimalColoring(
        _ balance: String,
        font: Font,
        integerColor: Color,
        decimalColor: Color
    ) -> AttributedString {
        var attributed = AttributedString(balance)
        attributed.font = font
        attributed.foregroundColor = integerColor

        let separator = Locale.current.decimalSeparator ?? "."
        if let range = attributed.range(of: separator) {
            attributed[range.lowerBound ..< attributed.endIndex].foregroundColor = decimalColor
        }

        return attributed
    }
}
