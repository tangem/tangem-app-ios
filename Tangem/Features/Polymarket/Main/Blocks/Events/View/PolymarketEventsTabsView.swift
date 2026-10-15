//
//  PolymarketEventsTabsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarketUI
import TangemUI

struct PolymarketEventsTabsView: View {
    @ObservedObject var viewModel: PolymarketEventsBlockViewModel

    var animatesStateChanges = true

    var body: some View {
        if viewModel.showsTabs {
            Group {
                if animatesStateChanges {
                    tabs.polymarketStateTransition(viewModel.categories.isEmpty)
                } else {
                    tabs
                }
            }
            .padding(.vertical, Constants.verticalPadding)
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
}

// MARK: - Constants

private extension PolymarketEventsTabsView {
    enum Constants {
        static let verticalPadding: CGFloat = 8
    }
}
