//
//  CommonStakingAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct CommonStakingAnalyticsLogger: StakingAnalyticsLogger {
    func logAPIError(errorDescription: String) {
        Analytics.log(event: .stakingErrors, params: [.errorDescription: errorDescription])
    }
}
