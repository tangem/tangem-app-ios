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
    func logAPIError(errorDescription: String, currencySymbol: String?) {
        var params: [Analytics.ParameterKey: String] = [.errorDescription: errorDescription]
        if let currencySymbol {
            params[.token] = currencySymbol
        }
        Analytics.log(event: .stakingErrors, params: params)
    }
}
