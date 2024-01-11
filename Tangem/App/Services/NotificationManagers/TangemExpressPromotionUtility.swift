//
//  TangemExpressPromotionUtility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TangemExpressPromotionUtility {
    var isPromotionRunning: Bool {
        let today = Date()
        let start = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2023, month: 12, day: 15).date!
        // Ends on midnight of 31 jan 2024
        let end = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2024, month: 2, day: 1).date!

        return start <= today && today < end
    }
}
