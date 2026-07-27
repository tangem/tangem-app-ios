//
//  MarketsCommonWidgetHeaderLoadingState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MarketsCommonWidgetHeaderLoadingState: Hashable {
    case first
    case retry
    case failed
    case loaded

    // UI Settings

    var isButtonVisibility: Bool {
        self == .loaded
    }

    var isHeaderSkeletonable: Bool {
        self == .first
    }
}
