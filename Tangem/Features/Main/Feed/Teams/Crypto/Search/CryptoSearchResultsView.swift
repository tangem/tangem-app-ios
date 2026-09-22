//
//  CryptoSearchResultsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct CryptoSearchResultsView: View {
    let rows: [MarketTokenItemViewModel]
    let onAppear: (MarketTokenItemViewModel) -> Void
    let onDisappear: (MarketTokenItemViewModel) -> Void

    var showsBackground = true

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(rows, id: \.tokenId) { row in
                MarketTokenRowView(viewModel: row)
                    .onAppear { onAppear(row) }
                    .onDisappear { onDisappear(row) }
            }
        }
        .roundedBackground(with: showsBackground ? DesignSystem.Color.bgSecondary : .clear, padding: 0, radius: Constants.cornerRadius)
        .padding(.horizontal, showsBackground ? Constants.horizontalPadding : 0)
    }
}

// MARK: - Constants

private extension CryptoSearchResultsView {
    enum Constants {
        static let cornerRadius: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
    }
}
