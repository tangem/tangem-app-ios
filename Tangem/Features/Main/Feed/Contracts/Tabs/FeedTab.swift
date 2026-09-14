//
//  FeedTab.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemMacro
import TangemUI

@RawCaseName
enum FeedTab: Identifiable {
    case crypto(CryptoFeedViewModel)
    case realAssets(RealAssetsFeedViewModel)
    case earn(EarnFeedViewModel)
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

    var promoBanner: PromotionNotificationsViewModel? {
        switch self {
        case .crypto(let viewModel): viewModel.promoBanner
        case .realAssets(let viewModel): viewModel.promoBanner
        case .earn(let viewModel): viewModel.promoBanner
        case .predictions: nil
        }
    }

    func feedSheetSizeDidChange(to size: ShtorkaSize) {
        switch self {
        case .crypto(let viewModel): viewModel.feedSheetSizeDidChange(to: size)
        case .realAssets(let viewModel): viewModel.feedSheetSizeDidChange(to: size)
        case .earn, .predictions: break
        }
    }
}

// MARK: - TabNavigationItem

extension FeedTab: TabNavigationItem {
    var title: String { kind.title }
    var icon: ImageType? { kind.icon }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
