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
            collapsedView: collapsedView,
            expandedView: expandedView,
            expandedViewHeader: expandedViewHeader,
            onExpandedChange: { _ in onAssetTap(item.id) }
        )
    }

    @ViewBuilder
    func expandedViewHeader() -> some View {
        // An expandable item is always resolved content, so this is present; a loading asset is inert.
        if let content = item.assetRow.content {
            ExpandedHeaderView(assetRow: content)
        }
    }

    func expandedView() -> some View {
        ExpandedNetworksView(networkRows: item.networkRows)
    }

    func collapsedView() -> some View {
        rowContent
    }

    var staticCard: some View {
        rowContent
            .portfolioTokenCard()
    }

    var rowContent: some View {
        // Aggregate row: no network badge — the asset spans networks (shown in the subtitle / child rows).
        RowView(row: item.assetRow, showsIndicator: true, isWithOverlays: false)
    }
}

private extension AnyTransition {
    static let expandedContentTransition: AnyTransition = .asymmetric(
        insertion: .offset(y: 20).combined(with: .opacity),
        removal: .opacity
    )
}
