//
//  PerformanceTracker+Metric.swift
//  TangemAnalytics
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public extension PerformanceTracker {
    /// The metric to track.
    enum Metric {
        case totalBalanceLoaded(tokensCount: Int)
        case swapQuotesLoaded(providersCount: Int)
    }
}
