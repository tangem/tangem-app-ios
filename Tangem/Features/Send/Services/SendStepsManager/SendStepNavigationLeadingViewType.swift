//
//  SendStepNavigationLeadingViewType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum SendStepNavigationLeadingViewType: Hashable {
    case closeButton
    case backButton

    static func == (lhs: SendStepNavigationLeadingViewType, rhs: SendStepNavigationLeadingViewType) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .closeButton:
            hasher.combine("closeButton")
        case .backButton:
            hasher.combine("backButton")
        }
    }
}
