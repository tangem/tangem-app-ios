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
    func logError(_ error: any Error, currencySymbol: String) {
        guard let entry = Mapper.map(error: error, currencySymbol: currencySymbol) else {
            return
        }

        Analytics.log(
            event: entry.event,
            params: entry.parameters
        )
    }
}
