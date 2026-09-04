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
    case predictions

    var title: String {
        switch self {
        case .crypto: Localization.feedTabCrypto
        case .predictions: Localization.predictionMainTitle
        }
    }

    var icon: ImageType {
        switch self {
        case .crypto: DesignSystem.Icons.ChartLineVertical.regular20
        case .predictions: DesignSystem.Icons.Gauge.regular20
        }
    }
}
