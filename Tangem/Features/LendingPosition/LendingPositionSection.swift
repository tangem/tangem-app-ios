//
//  LendingPositionSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

enum LendingPositionSection: CaseIterable, TabNavigationItem {
    case myFunds
    case benefits
    case details

    var id: Self { self }

    // [REDACTED_TODO_COMMENT]
    var title: String {
        switch self {
        case .myFunds: "My Funds"
        case .benefits: "Benefits"
        case .details: "Details"
        }
    }
}
