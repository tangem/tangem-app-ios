//
//  FeedSelection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedSelection: Equatable {
    case crypto(categoryId: String?)
    case realAssets(categoryId: String?)
    case earn(type: EarnFilterType?)

    var tabKind: FeedTabKind {
        switch self {
        case .crypto: .crypto
        case .realAssets: .realAssets
        case .earn: .earn
        }
    }
}
