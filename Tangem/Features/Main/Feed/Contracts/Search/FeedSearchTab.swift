//
//  FeedSearchTab.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemMacro
import TangemUI

@RawCaseName
enum FeedSearchTab: Identifiable {
    case crypto(CryptoSearchViewModel)
    case realAssets
    case earn(EarnSearchViewModel)
    case predictions

    var id: String { rawCaseValue }

    var kind: FeedTabKind {
        switch self {
        case .crypto: .crypto
        case .realAssets: .realAssets
        case .earn: .earn
        case .predictions: .predictions
        }
    }

    func setVisible(_ isVisible: Bool) {
        switch self {
        case .crypto(let viewModel): viewModel.setVisible(isVisible)
        case .earn(let viewModel): viewModel.setVisible(isVisible)
        case .realAssets, .predictions: break
        }
    }
}

// MARK: - TabNavigationItem

extension FeedSearchTab: TabNavigationItem {
    var title: String { kind.title }
    var icon: ImageType? { kind.icon }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
