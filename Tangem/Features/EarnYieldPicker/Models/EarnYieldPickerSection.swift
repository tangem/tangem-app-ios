//
//  EarnYieldPickerSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics
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

    static func current(
        sectionTops: [EarnYieldPickerSection: CGFloat],
        pinnedEdge: CGFloat,
        visibleBottom: CGFloat,
        remainingScroll: CGFloat
    ) -> EarnYieldPickerSection {
        let line = pinnedEdge + max(0, visibleBottom - pinnedEdge - remainingScroll)

        return allCases.last { section in
            sectionTops[section, default: .infinity] <= line
        } ?? .calculator
    }
}
