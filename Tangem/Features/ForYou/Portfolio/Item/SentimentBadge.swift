//
//  SentimentBadge.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

/// Placeholder price-change badge; real sentiment data lands with the price-change pipeline.
struct SentimentBadge: View {
    let sentiment: ForYouTokenRowData.Sentiment

    var body: some View {
        TangemBadgeV2(label: title, accessibilityLabel: nil)
            .size(.x4)
            .variant(.tinted)
            .appearance(appearance)
    }
}

private extension SentimentBadge {
    /// Placeholder, not localized — real label comes with price-change data from backend.
    var title: String {
        switch sentiment {
        case .positive: "Positive"
        case .neutral: "Neutral"
        case .negative: "Negative"
        }
    }

    var appearance: TangemBadgeV2Appearance {
        switch sentiment {
        case .positive: .success
        case .neutral: .info
        case .negative: .error
        }
    }
}
