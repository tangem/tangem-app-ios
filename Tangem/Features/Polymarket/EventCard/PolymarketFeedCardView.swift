//
//  PolymarketFeedCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarketUI

struct PolymarketFeedCardView: View {
    let card: PolymarketFeedCard

    var body: some View {
        switch card {
        case .regular(let model):
            PolymarketEventCard(model: model)
                .equatable()
        case .liveGame(let model):
            PolymarketLiveGameCard(model: model)
                .equatable()
        }
    }
}
