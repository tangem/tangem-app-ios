//
//  FiatAmountRoundingType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum FiatAmountRoundingType {
    case shortestFraction(roundingMode: NSDecimalNumber.RoundingMode)
    case `default`(roundingMode: NSDecimalNumber.RoundingMode, scale: Int = 2)
}
