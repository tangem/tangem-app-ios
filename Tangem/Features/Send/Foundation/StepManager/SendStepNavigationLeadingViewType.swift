//
//  SendStepNavigationLeadingViewType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemFoundation.IgnoredEquatable

enum SendStepNavigationLeadingViewType: Hashable {
    case closeButton
    case backButton
    case dotsMenu(items: [DotsMenuItem])
}

extension SendStepNavigationLeadingViewType {
    struct DotsMenuItem: Hashable {
        let id: String
        let title: String
        let isSelected: Bool
        @IgnoredEquatable var action: () -> Void
    }
}
