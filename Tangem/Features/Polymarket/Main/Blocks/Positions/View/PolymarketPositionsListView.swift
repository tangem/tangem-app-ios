//
//  PolymarketPositionsListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarketUI

struct PolymarketPositionsListView: View {
    let models: [PolymarketPositionRow.Model]
    let showsViewAll: Bool
    let onOpenPosition: (String) -> Void
    let onViewAll: () -> Void

    var body: some View {
        PolymarketPositionsViewAllSection(showsViewAll: showsViewAll, onViewAll: onViewAll) {
            ForEach(models) { model in
                PolymarketPositionRow(model: model) { onOpenPosition(model.id) }
            }
        }
    }
}
