//
//  FeedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @ObservedObject var searchViewModel: FeedSearchViewModel

    let shtorkaReporting: any MainShtorkaReporting
    let shtorkaActions: any MainShtorkaViewActionProvider

    @Environment(\.mainShtorkaSize) private var sheetSize

    @State private var isContentUnderSearchBar = false
    @State private var areChipsPinned = false

    var body: some View {
        content
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .navigationBar)
    }

    private var content: some View {
        VStack(spacing: 0) {
            searchBar

            ZStack {
                if searchViewModel.isActive {
                    FeedSearchView(viewModel: searchViewModel)
                } else {
                    feedScroll
                }
            }
            .infinityFrame(alignment: .top)
            .animation(.easeInOut(duration: Constants.searchTransitionDuration), value: searchViewModel.isActive)
        }
        .infinityFrame(alignment: .top)
    }

    private var searchBar: some View {
        FeedSearchBarView(
            viewModel: viewModel.searchBarViewModel,
            isActive: searchViewModel.isActive,
            onExpand: shtorkaActions.expand,
            onFocus: {
                searchViewModel.open()
                shtorkaActions.expand()
            },
            onCancel: searchViewModel.reset,
            onHeightChange: { shtorkaReporting.report(searchBar: $0) }
        )
    }

    private var feedScroll: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                let visibleHeight = max(0, viewport.size.height - FeedConstants.searchContentInset)

                ScrollView {
                    VStack(spacing: FeedConstants.widgetsToTabsSpacing) {
                        FeedWidgetsView(viewModel: viewModel.widgetsViewModel)
                            .readGeometry(\.size.height) { shtorkaReporting.report(widgets: $0) }

                        FeedTabsView(
                            viewModel: viewModel.tabsViewModel,
                            shtorkaActions: shtorkaActions,
                            areChipsPinned: $areChipsPinned,
                            scrollProxy: proxy,
                            scrollTarget: { shtorkaReporting.scrollTarget(forTab: $0, viewportHeight: visibleHeight, pinTabs: $1, chipsPinned: $2) },
                            onChipsHeightChange: { shtorkaReporting.report(tabChips: $0) }
                        )
                        .frame(minHeight: visibleHeight, alignment: .top)
                    }
                    .background(alignment: .top) {
                        Color.clear
                            .frame(height: FeedConstants.scrollAnchorHeight)
                            .id(FeedConstants.contentAnchorID)
                    }
                    .onGeometryChange(for: CGFloat.self, of: { -$0.frame(in: .named(FeedConstants.scrollCoordinateSpace)).minY }) { offset in
                        shtorkaReporting.report(scrollOffset: offset, tabID: viewModel.tabsViewModel.selectedTab.id)

                        let isUnderSearchBar = offset > 0
                        if isUnderSearchBar != isContentUnderSearchBar {
                            isContentUnderSearchBar = isUnderSearchBar
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: FeedConstants.scrollCoordinateSpace)
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear
                        .frame(height: FeedConstants.searchContentInset)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .top) {
                    if isContentUnderSearchBar, !areChipsPinned {
                        Fade(position: .top)
                            .frame(height: FeedConstants.topFadeHeight)
                    }
                }
                // An edge-attached collapsed sheet is taller than the search bar by this inset; keep the widgets out of it.
                .padding(.top, sheetSize.isCollapsedFeedSheet ? FeedConstants.collapsedBottomInset : 0)
                .onChange(of: sheetSize) { size in
                    guard let size else { return }

                    resetScroll(at: size, with: proxy)
                }
            }
        }
    }

    private func resetScroll(at size: ShtorkaSize, with proxy: ScrollViewProxy) {
        guard size != .full else {
            return
        }

        withAnimation {
            proxy.scrollTo(FeedConstants.contentAnchorID, anchor: .top)
            proxy.scrollTo(FeedConstants.widgetsAnchorID, anchor: .leading)
        }
    }
}

// MARK: - Constants

private extension FeedView {
    enum Constants {
        static let searchTransitionDuration: TimeInterval = 0.2
    }
}
