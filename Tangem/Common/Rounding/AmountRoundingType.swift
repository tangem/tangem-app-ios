//
//  AmountRoundingType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum AmountRoundingType {
    case shortestFraction(roundingMode: NSDecimalNumber.RoundingMode)
    case `default`(roundingMode: NSDecimalNumber.RoundingMode, scale: Int)

    static func `default`(roundingMode: NSDecimalNumber.RoundingMode) -> AmountRoundingType {
        return .default(roundingMode: roundingMode, scale: 2)
    }
}
