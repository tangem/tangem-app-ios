//
//  AmountRoundingType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum AmountRoundingType: Hashable {
    case shortestFraction(roundingMode: NSDecimalNumber.RoundingMode)
    case `default`(roundingMode: NSDecimalNumber.RoundingMode, scale: Int)
}

extension AmountRoundingType {
    var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .shortestFraction(let roundingMode):
            return roundingMode
        case .default(let roundingMode, _):
            return roundingMode
        }
    }
}
