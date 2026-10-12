//
//  FeedForYouWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct FeedForYouWidgetView: View {
    var body: some View {
        FeedCompactCardView(title: Localization.forYouTitle) {
            FeedPortfolioDonutView()
        }
    }
}
