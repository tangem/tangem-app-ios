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
        .animation(.polymarketStateChange, value: viewModel.selectedSubcategoryID)
    }

    @ViewBuilder
    private var subcategoryTabs: some View {
        let tabs = viewModel.subcategoryTabs

        if !tabs.isEmpty {
            TabNavigation(data: tabs, selection: viewModel.selectedSubcategoryTab)
                .variant(.material)
                .scrollable()
                .padding(.top, Constants.subcategoriesTopPadding)
        }
    }

    @ViewBuilder
    private var filterTabs: some View {
        let tabs = viewModel.filterTabs

        if !tabs.isEmpty {
            TabNavigation(data: tabs, selection: viewModel.selectedFilterTab)
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
