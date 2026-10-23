//
//  FeedSearchTabsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct FeedSearchTabsView: View {
    @ObservedObject var viewModel: FeedSearchTabsViewModel

    @State private var tabsHeight: CGFloat = 0

    var body: some View {
        pages
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear
                    .frame(height: tabsHeight)
                    .allowsHitTesting(false)
            }
            .reverseMask(alignment: .top) {
                FeedTopFade(height: Constants.fadeHeight, visibleHeight: tabsHeight + Constants.fadeBottomOverlap)
            }
            .overlay(alignment: .top) { tabsRow }
    }

    private var pages: some View {
        FeedTabPagerView(pager: viewModel.pager, selection: viewModel.selectedTab) { page in
            tabContent(for: page.tab)
        }
    }

    private var tabsRow: some View {
        TabNavigation(data: viewModel.tabs, selection: tabSelection)
            .variant(.material)
            .scrollable()
            .hapticFeedback()
            .padding(.top, FeedConstants.searchContentInset)
            .padding(.bottom, Constants.tabsSpacing)
            .readGeometry(\.size.height, bindTo: $tabsHeight)
    }

    @ViewBuilder
    private func tabContent(for tab: FeedSearchTab) -> some View {
        switch tab {
        case .crypto(let cryptoViewModel):
            CryptoSearchView(viewModel: cryptoViewModel)
        case .realAssets(let realAssetsViewModel):
            RealAssetsSearchView(viewModel: realAssetsViewModel)
        case .earn(let earnViewModel):
            EarnSearchView(viewModel: earnViewModel)
        case .predictions:
            // [REDACTED_TODO_COMMENT]
            FeedSearchEmptyView(title: "Search is not available in \(tab.title) yet")
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
        static let fadeHeight: CGFloat = 96
        static let fadeBottomOverlap: CGFloat = 9
    }
}
