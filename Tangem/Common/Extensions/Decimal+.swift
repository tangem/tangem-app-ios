//
//  Decimal+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    /// - Note: Unlike `BigDecimal.scale()` in Java https://docs.oracle.com/javase/7/docs/api/java/math/BigDecimal.html#scale()
    /// on iOS `scale` ignores trailing zeroes.
    var scale: Int {
        exponent < 0 ? -exponent : 0
    }

    var stringValue: String {
        (self as NSDecimalNumber).stringValue
    }

    var doubleValue: Double {
        (self as NSDecimalNumber).doubleValue
    }

    func intValue(roundingMode: NSDecimalNumber.RoundingMode = .down) -> Int {
        (rounded(roundingMode: roundingMode) as NSDecimalNumber).intValue
    }

    /// Parses given string using a fixed `en_US_POSIX` locale.
    /// - Note: Prefer this initializer to the `init?(string:locale:)` or `init?(_:)`.
    init?(stringValue: String?) {
        guard let stringValue = stringValue else {
            return nil
        }

        self.init(string: stringValue, locale: .posixEnUS)
    }
}
