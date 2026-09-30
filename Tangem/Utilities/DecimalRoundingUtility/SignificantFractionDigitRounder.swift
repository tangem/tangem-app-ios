//
//  SignificantFractionDigitRounder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct SignificantFractionDigitRounder {
    let roundingMode: NSDecimalNumber.RoundingMode

    func round(value: Decimal) -> Decimal {
        if value.isZero {
            return value
        }

        // `log10` of a negative number is NaN and `Int(NaN)` traps; the number of significant fraction digits
        // depends on the magnitude only.
        let log = Int(floor(log10(NSDecimalNumber(decimal: value.magnitude).doubleValue)))
        let scale = log < -1 ? -log : 2
        return value.rounded(scale: scale, roundingMode: roundingMode)
    }
}
