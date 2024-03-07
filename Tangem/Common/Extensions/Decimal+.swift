//
//  Decimal+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    func currencyFormatted(code: String, maximumFractionDigits: Int = 18) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencyCode = code
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = maximumFractionDigits
        if code == "RUB" {
            formatter.currencySymbol = "₽"
        }
        // formatter.roundingMode = .down
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self) \(code)"
    }

    var stringValue: String {
        (self as NSDecimalNumber).stringValue
    }

    /// Parses given string using a fixed `en_US_POSIX` locale; prefer this initializer to the `init(string:locale:)`.
    init?(stringValue: String) {
        self.init(string: stringValue, locale: .posixEnUS)
    }
}

// MARK: - Private implementation

private extension Locale {
    /// Locale for string literals parsing.
    static let posixEnUS = Locale(identifier: "en_US_POSIX")
}
