//
//  SentimentBadge.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

/// Badge showing a token's aggregate coin-indicator sentiment for the selected period.
struct SentimentBadge: View {
    let sentiment: ForYouTokenRowData.Sentiment

    var body: some View {
        Badge(label: title, accessibilityLabel: nil)
            .size(.x4)
            .variant(.tinted)
            .appearance(appearance)
    }
}

private extension SentimentBadge {
    var title: String {
        switch sentiment {
        case .positive: Localization.commonPositive
        case .neutral: Localization.commonNeutral
        case .negative: Localization.commonNegative
        }
    }

    var appearance: BadgeAppearance {
        switch sentiment {
        case .positive: .success
        case .neutral: .info
        case .negative: .error
        }
    }
}
