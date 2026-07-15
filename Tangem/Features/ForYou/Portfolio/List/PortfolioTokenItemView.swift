//
//  PortfolioTokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct PortfolioTokenItemView: View {
    let item: ForYouTokenListItem
    let onAssetTap: (String) -> Void

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private extension PortfolioTokenItemView {
    // MARK: - Content

    @ViewBuilder
    var content: some View {
        if item.isExpanded {
            ExpandedRowView(
                assetRow: item.assetRow,
                networkRows: item.networkRows,
                onToggle: toggle
            )
        } else {
            collapsedRow
                .transition(.opacity)
        }
    }

    // MARK: - Collapsed aggregate row

    var collapsedRow: some View {
        RowView(data: item.assetRow, showsIndicator: true)
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture(perform: toggle)
    }

    // MARK: - Actions

    func toggle() {
        guard item.isExpandable else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            onAssetTap(item.id)
        }
    }
}

// MARK: - Previews

#Preview("Collapsed") {
    let icon = TokenIconInfo(
        name: "",
        blockchainIconAsset: nil,
        imageURL: IconURLBuilder().tokenIconURL(id: "bitcoin"),
        isCustom: false,
        customTokenColor: nil
    )

    return PortfolioTokenItemView(
        item: ForYouTokenListItem(
            id: "btc",
            assetRow: ForYouTokenRowData(
                id: "btc",
                isLoading: false,
                symbol: "Bitcoin",
                tokenIconInfo: icon,
                sentiment: .positive,
                subtitle: .text("Main network"),
                end: .values(fiat: "$849", percent: "8.49%")
            ),
            networkRows: [],
            isExpanded: false,
            isExpandable: true
        ),
        onAssetTap: { _ in }
    )
    .padding(16)
}
