//
//  StakingAnalyticsLogger.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAnalyticsLogger {
    func logError(_ error: any Error, currencySymbol: String)
}
