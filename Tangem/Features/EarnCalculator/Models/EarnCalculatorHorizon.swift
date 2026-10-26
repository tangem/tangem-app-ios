//
//  EarnCalculatorHorizon.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum EarnCalculatorHorizon: CaseIterable, Hashable {
    case sixMonths
    case oneYear
    case threeYears
    case fiveYears
    case tenYears

    var months: Int {
        switch self {
        case .sixMonths: 6
        case .oneYear: 12
        case .threeYears: 36
        case .fiveYears: 60
        case .tenYears: 120
        }
    }

    // [REDACTED_TODO_COMMENT]
    var menuTitle: String {
        switch self {
        case .sixMonths: "6 Months"
        case .oneYear: "1 Year"
        case .threeYears: "3 Years"
        case .fiveYears: "5 Years"
        case .tenYears: "10 Years"
        }
    }

    // [REDACTED_TODO_COMMENT]
    var inlineTitle: String {
        switch self {
        case .sixMonths: "6 months"
        case .oneYear: "1 year"
        case .threeYears: "3 years"
        case .fiveYears: "5 years"
        case .tenYears: "10 years"
        }
    }

    var axisTicks: [AxisTick] {
        switch self {
        case .sixMonths: [.init(month: 1, label: "1M"), .init(month: 3, label: "3M"), .init(month: 6, label: "6M")]
        case .oneYear: [.init(month: 1, label: "1M"), .init(month: 6, label: "6M"), .init(month: 12, label: "1Y")]
        case .threeYears: [.init(month: 12, label: "1Y"), .init(month: 24, label: "2Y"), .init(month: 36, label: "3Y")]
        case .fiveYears: [.init(month: 12, label: "1Y"), .init(month: 36, label: "3Y"), .init(month: 60, label: "5Y")]
        case .tenYears: [.init(month: 12, label: "1Y"), .init(month: 60, label: "5Y"), .init(month: 120, label: "10Y")]
        }
    }
}

extension EarnCalculatorHorizon {
    struct AxisTick: Hashable {
        let month: Int
        let label: String
    }
}
