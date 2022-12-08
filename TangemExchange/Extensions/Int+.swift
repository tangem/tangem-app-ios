//
//  Int+.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Int {
    var decimalNumber: Decimal {
        pow(10, self)
    }
}
