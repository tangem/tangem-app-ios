//
//  PolymarketNoActivePositionsBlockContent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarketUI

struct PolymarketNoActivePositionsBlockContent: View {
    let showsViewAll: Bool
    let onViewAll: () -> Void

    var body: some View {
        PolymarketPositionsViewAllSection(showsViewAll: showsViewAll, onViewAll: onViewAll) {
            PolymarketNoActivePositionsView()
        }
    }
}
