//
//  PortfolioTokenItemView+ExpandedNetworksView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension PortfolioTokenItemView {
    struct ExpandedNetworksView: View {
        let networkRows: [ForYouTokenRowData]

        var body: some View {
            VStack(spacing: 0) {
                ForEach(networkRows, content: rowContent)
            }
        }

        @ViewBuilder
        private func rowContent(_ row: ForYouTokenRowData) -> some View {
            if row.isLoading {
                TangemTwoLineRowSkeletonView()
                    .transition(.opacity)
            } else {
                RowView(data: row)
                    .transition(.opacity)
            }
        }
    }
}
