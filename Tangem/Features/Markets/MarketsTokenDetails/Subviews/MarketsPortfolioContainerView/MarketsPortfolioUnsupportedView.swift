//
//  MarketsPortfolioUnsupportedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization

struct MarketsPortfolioUnsupportedView: View {
    let iconURL: URL

    var body: some View {
        MarketsPortfolioPlateView(iconURL: iconURL, title: title) {
            EmptyView()
        }
        .accessibilityIdentifier(MainAccessibilityIdentifiers.tokenNotSupportedNotice)
    }

    private var title: AttributedString {
        MarketsPortfolioPlateTitle.make(
            Localization.marketsPortfolioBlockTokenUnsupported,
            emphasizedColor: Color.Tangem.Text.Neutral.primary
        )
    }
}
