//
//  FeedTabKind.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

enum FeedTabKind {
    case crypto
    case realAssets
    case earn
    case predictions

    var title: String {
        switch self {
        case .crypto: Localization.feedTabCrypto
        case .realAssets: Localization.marketsRealAssetsTitle
        case .earn: Localization.feedTabEarn
        case .predictions: Localization.predictionMainTitle
        }
    }

    var icon: ImageType {
        switch self {
        case .crypto: DesignSystem.Icons.ChartLineVertical.regular20
        case .realAssets: DesignSystem.Icons.Government.regular20
        case .earn: DesignSystem.Icons.CoinsStackArrowUp.regular20
        case .predictions: DesignSystem.Icons.Gauge.regular20
        }
    }
}
