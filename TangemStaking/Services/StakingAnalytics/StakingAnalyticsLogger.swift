//
//  StakingAnalyticsLogger.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAnalyticsLogger {
    func logAPIError(errorDescription: String, currencySymbol: String?)
}
