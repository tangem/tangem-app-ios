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
    @ObservedObject var shtorkaStateObject: MainShtorkaStateObject

    @State private var isContentUnderSearchBar = false
    @State private var areChipsPinned = false

    var body: some View {
        content
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: shtorkaStateObject.size, perform: viewModel.sheetSizeDidChange)
            .onChange(of: searchViewModel.isActive) { isActive in
                if isActive {
                    shtorkaStateObject.expand()
                }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            searchBar

            ZStack {
                if searchViewModel.isActive {
                    FeedSearchView(viewModel: searchViewModel)
                        .padding(.top, FeedConstants.searchContentInset)
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
            shtorkaStateObject: shtorkaStateObject,
            isActive: searchViewModel.isActive,
            onFocus: searchViewModel.open,
            onCancel: searchViewModel.reset
        )
    }

    private var feedScroll: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: FeedConstants.widgetsToTabsSpacing) {
                        FeedWidgetsView(viewModel: viewModel.widgetsViewModel)
                            .readGeometry(\.size.height) { shtorkaStateObject.report(widgets: $0) }

                        FeedTabsView(
                            viewModel: viewModel.tabsViewModel,
                            shtorkaStateObject: shtorkaStateObject,
                            areChipsPinned: $areChipsPinned,
                            onTabChange: { restoreScroll(tabID: $0, viewportHeight: viewport.size.height - FeedConstants.searchContentInset, with: proxy) }
                        )
                        .frame(minHeight: max(0, viewport.size.height - FeedConstants.searchContentInset), alignment: .top)
                    }
                    .background(alignment: .top) {
                        Color.clear
                            .frame(height: FeedConstants.scrollAnchorHeight)
                            .id(FeedConstants.contentAnchorID)
                    }
                    .onGeometryChange(for: CGFloat.self, of: { -$0.frame(in: .named(FeedConstants.scrollCoordinateSpace)).minY }) { offset in
                        shtorkaStateObject.report(scrollOffset: offset, tabID: viewModel.tabsViewModel.selectedTab.id)

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
                .padding(.top, shtorkaStateObject.size == .collapsed ? FeedConstants.collapsedBottomInset : 0)
                .onChange(of: shtorkaStateObject.size) { size in
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

    private func restoreScroll(tabID: String, viewportHeight: CGFloat, with proxy: ScrollViewProxy) {
        guard let anchor = shtorkaStateObject.scrollAnchor(forTab: tabID, viewportHeight: viewportHeight) else {
            return
        }

        proxy.scrollTo(FeedConstants.contentAnchorID, anchor: anchor)
    }
}

// MARK: - Constants

private extension FeedView {
    enum Constants {
        static let searchTransitionDuration: TimeInterval = 0.2
    }
}
