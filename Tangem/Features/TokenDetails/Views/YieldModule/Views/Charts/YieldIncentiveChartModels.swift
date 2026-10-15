//
//  YieldIncentiveChartModels.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI

enum YieldIncentiveChartPeriod: Int, CaseIterable, Identifiable, Hashable {
    case week = 7
    case threeMonths = 90

    var id: Self { self }

    var days: Int { rawValue }
}

// MARK: - TangemSegmentedPickerTextProvider

extension YieldIncentiveChartPeriod: TangemSegmentedPickerTextProvider {
    var text: String {
        switch self {
        case .week:
            Localization.yieldModuleIncentiveChartPeriodWeek
        case .threeMonths:
            Localization.yieldModuleIncentiveChartPeriodThreeMonths
        }
    }
}

struct YieldIncentiveChartData: Equatable {
    let baseApyData: [Double]
    let totalApyData: [Double]
    let xTicks: [Int: String]
    let averageApy: Double?
}
