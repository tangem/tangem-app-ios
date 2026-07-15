//
//  SentimentBadge.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

/// Placeholder price-change badge; real sentiment data lands with the price-change pipeline.
struct SentimentBadge: View {
    let sentiment: ForYouTokenRowData.Sentiment

    var body: some View {
        Text(title)
            .style(DesignSystem.Font.captionMediumToken, color: colors.foreground)
            .padding(.horizontal, 4)
            .frame(minHeight: 16)
            .background(colors.background)
            .clipShape(Capsule())
    }
}

private extension SentimentBadge {
    /// Placeholder, not localized - real label comes with price-change data from backend.
    var title: String {
        switch sentiment {
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        }
    }

    var colors: (foreground: Color, background: Color) {
        switch sentiment {
        case .negative:
            return (DesignSystem.Color.textStatusError, DesignSystem.Color.bgStatusErrorSubtle)
        case .neutral:
            return (DesignSystem.Color.textStatusInfo, DesignSystem.Color.bgStatusInfoSubtle)
        case .positive:
            return (DesignSystem.Color.textStatusSuccess, DesignSystem.Color.bgStatusSuccessSubtle)
        }
    }
}
