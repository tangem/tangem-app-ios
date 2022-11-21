//
//  Decimal_.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    func currencyFormatted(code: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencyCode = code
        if code == "RUB" {
            formatter.currencySymbol = "₽"
        }
        // formatter.roundingMode = .down
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self) \(code)"
    }

    func groupedFormatted() -> String {
        let formatter = NumberFormatter.grouped
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }

    func decimalSeparator() -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        return formatter.decimalSeparator
    }
}
