//
//  PerformanceTracker+Result.swift
//  TangemAnalytics
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public extension PerformanceTracker {
    /// The result of tracking a metric.
    enum Result: Equatable {
        case success
        case failure
        case unspecified
    }
}
