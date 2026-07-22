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
        let onTokenSelect: (String) -> Void

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
                SwiftUI.Button {
                    onTokenSelect(row.id)
                } label: {
                    RowView(data: row)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
    }
}
