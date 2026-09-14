//
//  BigUInt+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BigInt.BigUInt
import struct BigInt.BigInt
import TangemFoundation

public extension BigUInt {
    static let maxUInt256 = BigUInt(2).power(256) - 1

    /// The form the JSON-RPC quantity fields take: `0x`, no leading zeroes, `0x0` for zero.
    var hexString: String {
        isZero ? "0x0" : "0x" + String(self, radix: 16)
    }

    /// Integer arithmetic, so the result is rounded down to a whole unit.
    func increased(byPercent percent: BigUInt) -> BigUInt {
        self * (100 + percent) / 100
    }

    /// - Note: Based on https://github.com/attaswift/BigInt/issues/52
    /// - Warning: May lead to a loss of precision.
    var decimal: Decimal? {
        let bigUIntFormatted = String(self)

        // Check that the decimal has been correctly formatted from the string without any loss
        guard
            let result = Decimal(stringValue: bigUIntFormatted),
            let decimalFormatted = NumberFormatter.bigIntNumberFormatter.string(from: NSDecimalNumber(decimal: result)),
            decimalFormatted == bigUIntFormatted
        else {
            return nil
        }

        return result
    }

    /// 1. For integers only, will return `nil` if the value isn't an integer number.
    /// 2. The given value will be clamped in the `0..<2^256>` range.
    init?(decimal decimalValue: Decimal) {
        if decimalValue < .zero {
            return nil
        } else if decimalValue.isZero {
            // Clamping to the min representable value
            self = .zero
        } else if decimalValue >= .greatestFiniteMagnitude {
            // Clamping to the max representable value
            self = .maxUInt256
        } else {
            // We're using a fixed locale here to avoid any possible ambiguity with the string representation
            let stringValue = decimalValue.decimalNumber.description(withLocale: Locale.posixEnUS)
            self.init(stringValue, radix: 10)
        }
    }
}

public extension BigInt {
    /// - Note: Based on https://github.com/attaswift/BigInt/issues/52
    /// - Warning: May lead to a loss of precision.
    var decimal: Decimal? {
        let bigIntFormatted = String(self)

        // Check that the decimal has been correctly formatted from the string without any loss
        guard
            let result = Decimal(stringValue: bigIntFormatted),
            let decimalFormatted = NumberFormatter.bigIntNumberFormatter.string(from: NSDecimalNumber(decimal: result)),
            decimalFormatted == bigIntFormatted
        else {
            return nil
        }

        return result
    }
}

// MARK: - Private implementation

private extension NumberFormatter {
    static let bigIntNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .posixEnUS
        formatter.usesGroupingSeparator = false
        return formatter
    }()
}
