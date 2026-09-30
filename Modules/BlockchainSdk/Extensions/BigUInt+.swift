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
            self = BigUInt(2).power(256) - 1
        } else {
            // We're using a fixed locale here to avoid any possible ambiguity with the string representation
            let stringValue = decimalValue.decimalNumber.description(withLocale: Locale.posixEnUS)
            self.init(stringValue, radix: 10)
        }
    }

    /// - Note: Based on https://github.com/attaswift/BigInt/issues/52
    /// - Warning: May lead to a loss of precision.
    var decimal: Decimal? {
        let bigUIntFormatted = String(self)

        // Check that the decimal has been correctly formatted from the string without any loss
        guard
            let result = Decimal(stringValue: bigUIntFormatted),
            let decimalFormatted = Self.decimalFormatter.string(from: NSDecimalNumber(decimal: result)),
            decimalFormatted == bigUIntFormatted
        else {
            return nil
        }

        return result
    }

    /// A `Decimal` that never traps. Unlike `Decimal(UInt64(self))`, it does not overflow for values above
    /// `UInt64.max` — a fee/gas value that large (from a dApp or a misbehaving RPC) used to crash the app on
    /// every fee refresh. Precision may be lost for such values, which is acceptable: the fee is unusable anyway.
    var decimalOrClamped: Decimal {
        decimal ?? Decimal(string: String(self)) ?? .greatestFiniteMagnitude
    }

    private static var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .posixEnUS
        formatter.usesGroupingSeparator = false
        return formatter
    }()
}

public extension BigInt {
    /// - Note: Based on https://github.com/attaswift/BigInt/issues/52
    /// - Warning: May lead to a loss of precision.
    var decimal: Decimal? {
        let bigIntFormatted = String(self)

        // Check that the decimal has been correctly formatted from the string without any loss
        guard
            let result = Decimal(stringValue: bigIntFormatted),
            let decimalFormatted = Self.decimalFormatter.string(from: NSDecimalNumber(decimal: result)),
            decimalFormatted == bigIntFormatted
        else {
            return nil
        }

        return result
    }

    private static var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .posixEnUS
        formatter.usesGroupingSeparator = false
        return formatter
    }()
}
