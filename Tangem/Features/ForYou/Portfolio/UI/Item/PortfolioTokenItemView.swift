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

    @Namespace private var namespace

    var body: some View {
        if item.isAssetLoading {
            TangemTwoLineRowSkeletonView()
                .portfolioTokenCard()
                .transition(.opacity)
        } else if item.isExpandable {
            expandableCard
                .transition(.opacity)
        } else {
            staticCard
                .transition(.opacity)
        }
    }
}

private extension PortfolioTokenItemView {
    var effects: PortfolioTokenGeometryEffects {
        PortfolioTokenGeometryEffects(namespace: namespace)
    }

    var expandableCard: some View {
        ExpandableItemView(
            isExpanded: item.isExpanded,
            backgroundColor: DesignSystem.Color.bgSecondary,
            cornerRadius: 24,
            backgroundGeometryEffect: effects.background,
            expandedViewTransition: .expandedContentTransition,
            collapsedView: collapsedView,
            expandedView: expandedView,
            expandedViewHeader: expandedViewHeader,
            onExpandedChange: { _ in onAssetTap(item.id) }
        )
    }

    func expandedViewHeader() -> some View {
        ExpandedHeaderView(assetRow: item.assetRow, effects: effects)
    }

    func expandedView() -> some View {
        ExpandedNetworksView(networkRows: item.networkRows)
    }

    func collapsedView() -> some View {
        RowView(data: item.assetRow, showsIndicator: true, effects: effects)
    }

    var staticCard: some View {
        RowView(data: item.assetRow, showsIndicator: true)
            .portfolioTokenCard()
    }
}

private extension AnyTransition {
    static let expandedContentTransition: AnyTransition = .asymmetric(
        insertion: .offset(y: 20).combined(with: .opacity),
        removal: .opacity
    )
}
