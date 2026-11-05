//
//  PolymarketEventsTabsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemPolymarketUI
import TangemUI

struct PolymarketEventsTabsView: View {
    @ObservedObject var viewModel: PolymarketEventsBlockViewModel

    var animatesStateChanges = true

    var body: some View {
        if viewModel.showsTabs {
            VStack(spacing: Constants.rowSpacing) {
                Group {
                    if animatesStateChanges {
                        tabs.polymarketStateTransition(viewModel.categories.isEmpty)
                    } else {
                        tabs
                    }
                }

                subcategoryTabs
            }
            .padding(.vertical, Constants.verticalPadding)
            .animation(animatesStateChanges ? .polymarketStateChange : nil, value: viewModel.selectedCategoryID)
        }
    }

    @ViewBuilder
    private var tabs: some View {
        if viewModel.categories.isEmpty {
            PolymarketCategoriesSkeletonView()
        } else {
            TabNavigation(data: viewModel.categoryTabs, selection: viewModel.selectedCategoryTab)
                .variant(.material)
                .scrollable()
        }
    }

    @ViewBuilder
    private var subcategoryTabs: some View {
        let tabs = viewModel.subcategoryTabs

        if !tabs.isEmpty {
            HStack(spacing: 0) {
                TabNavigation(data: tabs, selection: viewModel.selectedSubcategoryTab)
                    .variant(.material)
                    .scrollable()
                    .clipped()

                seeAllButton
            }
            .id(viewModel.selectedCategoryID)
            .transition(.polymarketState)
        }
    }

    private var seeAllButton: some View {
        TangemUI.Button(
            label: Localization.commonSeeAll,
            accessibilityLabel: Localization.commonSeeAll,
            action: { viewModel.handleViewAction(.seeAllTapped) }
        )
        .size(.x7)
        .styleType(.ghost)
        .padding(.trailing, PolymarketMainLayout.horizontalPadding)
    }
}

// MARK: - Constants

private extension PolymarketEventsTabsView {
    enum Constants {
        static let verticalPadding: CGFloat = 8
        static let rowSpacing: CGFloat = 12
    }
}
