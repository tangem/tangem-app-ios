//
//  YieldChartData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct YieldChartData: Equatable {
    let buckets: [Double]
    let averageApy: Double
    let maxApy: Double
    let xLabels: [String]
}
