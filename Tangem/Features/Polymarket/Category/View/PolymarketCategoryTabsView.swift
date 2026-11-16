//
//  PolymarketCategoryTabsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarketUI
import TangemUI

struct PolymarketCategoryTabsView: View {
    @ObservedObject var viewModel: PolymarketEventsBlockViewModel

    var body: some View {
        VStack(spacing: 0) {
            subcategoryTabs

            filterTabs
        }
    }

    @ViewBuilder
    private var subcategoryTabs: some View {
        let tabs = viewModel.subcategoryTabs

        if !tabs.isEmpty {
            TabNavigation(data: tabs, selection: viewModel.selectedSubcategoryTab.animation(.polymarketStateChange))
                .variant(.material)
                .scrollable()
                .padding(.top, Constants.subcategoriesTopPadding)
        }
    }

    @ViewBuilder
    private var filterTabs: some View {
        let tabs = viewModel.filterTabs

        if !tabs.isEmpty {
            TabNavigation(data: tabs, selection: viewModel.selectedFilterTab.animation(.polymarketStateChange))
                .variant(.material)
                .scrollable()
                .padding(.vertical, Constants.filtersVerticalPadding)
                .transition(.polymarketState)
        }
    }
}

// MARK: - Constants

private extension PolymarketCategoryTabsView {
    enum Constants {
        static let subcategoriesTopPadding: CGFloat = 8
        static let filtersVerticalPadding: CGFloat = 12
    }
}
