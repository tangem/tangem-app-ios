//
//  PolymarketWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct PolymarketWidgetView: View {
    var body: some View {
        FeedProductCardView(
            caption: Localization.predictionMainTitle,
            message: Localization.predictionAccountSubtitle,
            appearance: .polymarket
        )
    }
}
