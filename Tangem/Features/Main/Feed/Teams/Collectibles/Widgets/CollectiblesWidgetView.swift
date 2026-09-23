//
//  CollectiblesWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct CollectiblesWidgetView: View {
    var body: some View {
        FeedProductCardView(
            caption: Localization.collectiblesEntranceCardTitle,
            message: Localization.collectiblesEntranceCardSubtitle,
            appearance: .collectibles
        )
    }
}
