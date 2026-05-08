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
    case dotsMenu(items: [DotsMenuItem])

    static func == (lhs: SendStepNavigationLeadingViewType, rhs: SendStepNavigationLeadingViewType) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .closeButton:
            hasher.combine("closeButton")
        case .backButton:
            hasher.combine("backButton")
        case .dotsMenu(let items):
            hasher.combine("dotsMenu")
            hasher.combine(items)
        }
    }
}

extension SendStepNavigationLeadingViewType {
    struct DotsMenuItem: Hashable {
        let id: String
        let title: String
        let isSelected: Bool
        let action: () -> Void

        static func == (lhs: DotsMenuItem, rhs: DotsMenuItem) -> Bool {
            lhs.id == rhs.id && lhs.title == rhs.title && lhs.isSelected == rhs.isSelected
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(title)
            hasher.combine(isSelected)
        }
    }
}
