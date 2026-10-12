//
//  CryptoSearchResultsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct CryptoSearchResultsView: View {
    let rows: [MarketTokenItemViewModel]
    let onAppear: (MarketTokenItemViewModel) -> Void
    let onDisappear: (MarketTokenItemViewModel) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(rows, id: \.tokenId) { row in
                MarketTokenRowView(viewModel: row)
                    .onAppear { onAppear(row) }
                    .onDisappear { onDisappear(row) }
            }
        }
    }
}
