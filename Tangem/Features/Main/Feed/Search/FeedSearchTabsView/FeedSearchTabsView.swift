//
//  FeedSearchTabsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct FeedSearchTabsView: View {
    @ObservedObject var viewModel: FeedSearchTabsViewModel

    var body: some View {
        VStack(spacing: Constants.tabsSpacing) {
            TabNavigation(data: viewModel.tabs, selection: tabSelection)
                .variant(.material)
                .scrollable()
                .hapticFeedback()

            tabContent
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .crypto(let cryptoViewModel):
            CryptoSearchView(viewModel: cryptoViewModel)
        case .earn(let earnViewModel):
            EarnSearchView(viewModel: earnViewModel)
        case .realAssets, .predictions:
            // [REDACTED_TODO_COMMENT]
            FeedSearchEmptyView(title: "Search is not available in \(viewModel.selectedTab.title) yet")
        }
    }

    private var tabSelection: Binding<FeedSearchTab> {
        Binding(
            get: { viewModel.selectedTab },
            set: { viewModel.onSelectTab($0) }
        )
    }
}

// MARK: - Constants

private extension FeedSearchTabsView {
    enum Constants {
        static let tabsSpacing: CGFloat = 12
    }
}
