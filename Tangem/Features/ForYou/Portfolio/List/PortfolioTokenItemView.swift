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
        if item.isExpandable {
            expandableCard
        } else {
            staticCard
        }
    }
}

private extension PortfolioTokenItemView {
    var expandableCard: some View {
        ExpandableItemView(
            isExpanded: item.isExpanded,
            backgroundColor: DesignSystem.Color.bgSecondary,
            cornerRadius: 24,
            expandedViewTransition: .expandedContentTransition,
            collapsedView: {
                RowView(data: item.assetRow, showsIndicator: true)
                    .padding(16)
            },
            expandedView: {
                ExpandedNetworksView(networkRows: item.networkRows)
            },
            expandedViewHeader: {
                ExpandedHeaderView(assetRow: item.assetRow)
            },
            onExpandedChange: { _ in onAssetTap(item.id) }
        )
    }

    var staticCard: some View {
        RowView(data: item.assetRow, showsIndicator: true)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private extension AnyTransition {
    static let expandedContentTransition: AnyTransition = .asymmetric(
        insertion: .offset(y: 20).combined(with: .opacity),
        removal: .opacity
    )
}
