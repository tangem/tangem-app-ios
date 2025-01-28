//
//  PerformanceTracker+Metric.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension PerformanceTracker {
    /// The metric to track.
    enum Metric {
        case totalBalanceLoaded(tokensCount: Int)
    }
}
