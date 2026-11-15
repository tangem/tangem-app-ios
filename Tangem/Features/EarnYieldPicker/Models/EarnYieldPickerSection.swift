//
//  EarnYieldPickerSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

enum EarnYieldPickerSection: CaseIterable, TabNavigationItem {
    case calculator
    case benefits
    case details

    var id: Self { self }

    // [REDACTED_TODO_COMMENT]
    var title: String {
        switch self {
        case .calculator: "Calculator"
        case .benefits: "Benefits"
        case .details: "Details"
        }
    }
}
