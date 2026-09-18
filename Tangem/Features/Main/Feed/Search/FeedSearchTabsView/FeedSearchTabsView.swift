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
        tabContent
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear
                    .frame(height: tabsHeight)
                    .allowsHitTesting(false)
            }
            // Fade the content without painting over the sheet's changing glass background.
            .mask {
                Rectangle()
                    .overlay(alignment: .top) {
                        tabsFade.blendMode(.destinationOut)
                    }
            }
            .overlay(alignment: .top) { tabsRow }
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

    private var tabsFade: some View {
        Fade(position: .top)
            .variant(.hard)
            .backgroundColor(.black)
            .frame(height: Constants.fadeHeight)
            .frame(height: tabsHeight + Constants.fadeBottomOverlap, alignment: .bottom)
            .clipped()
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
        static let fadeHeight: CGFloat = 96
        static let fadeBottomOverlap: CGFloat = 9
    }
}
