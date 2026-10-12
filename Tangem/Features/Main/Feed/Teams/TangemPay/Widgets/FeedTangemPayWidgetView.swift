//
//  FeedTangemPayWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct FeedTangemPayWidgetView: View {
    var body: some View {
        FeedProductCardView(
            caption: Localization.feedPromoTangemPayTitle,
            message: Localization.feedPromoTangemPayDescription,
            appearance: .pay
        )
    }
}
