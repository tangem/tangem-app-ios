//
//  SwapAmountFraction.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum SwapAmountFraction: CaseIterable {
    case quarter
    case half
    case threeQuarters
    case max

    var percent: Int {
        switch self {
        case .quarter: return 25
        case .half: return 50
        case .threeQuarters: return 75
        case .max: return 100
        }
    }

    var multiplier: Decimal {
        Decimal(percent) / 100
    }

    var title: String {
        switch self {
        case .max:
            return Localization.sendMaxAmount
        case .quarter, .half, .threeQuarters:
            return "\(percent)%"
        }
    }

    var accessibilityIdentifierToken: String {
        switch self {
        case .quarter, .half, .threeQuarters:
            return "\(percent)"
        case .max:
            return "max"
        }
    }

    var analyticsValue: String {
        switch self {
        case .quarter, .half, .threeQuarters:
            return "\(percent)"
        case .max:
            return Analytics.ParameterValue.max.rawValue
        }
    }
}
