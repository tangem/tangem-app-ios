//
//  YieldIncentiveAprPoint.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A daily point of the incentivised-yield history, in the order returned by the backend.
/// All rates are in the same fraction form as `YieldModuleMarketInfo.apy`.
struct YieldIncentiveAprPoint: Equatable {
    let date: Date
    let baseApy: Decimal
    /// Estimated total APY (base + net rewards) as sent by the backend — never summed locally.
    let totalApyEst: Decimal
}
