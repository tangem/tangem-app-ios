//
//  YieldModuleDTO+AprHistory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension YieldModuleDTO.Response {
    struct AprHistory: Decodable {
        let points: [AprHistoryPoint]
    }

    struct AprHistoryPoint: Decodable {
        /// UTC day in the `YYYY-MM-DD` form.
        let date: String
        let baseApy: Decimal
        let grossTotalApyEst: Decimal
    }
}
