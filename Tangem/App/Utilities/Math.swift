//
//  Math.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct Math {
    func inverseLerp(from lowerBound: Decimal, to upperBound: Decimal, value: Decimal) -> Decimal {
        return min(1, (value - lowerBound) / (upperBound - lowerBound))
    }
}
