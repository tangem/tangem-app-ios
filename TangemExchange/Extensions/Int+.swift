//
//  Int+.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Int {
    var asLongNumber: Int {
        (0 ..< self).reduce(1) { number, _ in number * 10 }
    }
}
