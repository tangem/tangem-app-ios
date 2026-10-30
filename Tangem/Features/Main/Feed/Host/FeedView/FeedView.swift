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

    let container: any FeedContainer
    let isContentVisible: Bool

    @Environment(\.feedDetentReporting) private var detentReporting
    @Environment(\.mainShtorkaSize) private var sheetSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var areChipsPinned = false

    var body: some View {
        content
            .messageBannerNeutralVariant(.light)
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .navigationBar)
    }

    private var content: some View {
        VStack(spacing: 0) {
            searchBar

            ZStack {
                if searchViewModel.isActive {
                    FeedSearchTabsView(viewModel: searchViewModel.tabsViewModel)
                        .infinityFrame(alignment: .top)
                } else {
                    feedScroll
                }
            }
            .infinityFrame(alignment: .top)
            .animation(.easeInOut(duration: Constants.searchTransitionDuration), value: searchViewModel.isActive)
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(TapGesture().onEnded { viewModel.searchBarViewModel.endEditing() })
        }
        .infinityFrame(alignment: .top)
    }

    private var searchBar: some View {
        FeedSearchBarView(
            viewModel: viewModel.searchBarViewModel,
            isActive: searchViewModel.isActive,
            onFocus: container.expand,
            onCancel: searchViewModel.reset,
            onHeightChange: { detentReporting?.report(searchBar: $0) }
        )
    }

    private var feedScroll: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                let visibleHeight = max(0, viewport.size.height - FeedConstants.searchContentInset)

                ScrollView {
                    VStack(spacing: FeedConstants.widgetsToTabsSpacing) {
                        FeedWidgetsView(
                            viewModel: viewModel.widgetsViewModel,
                            viewport: viewport.frame(in: .global),
                            isContentVisible: isContentVisible && !searchViewModel.isActive
                        )
                        .readGeometry(\.size.height) { height in
                            viewModel.widgetsHeightDidChange(height)
                            detentReporting?.report(widgets: height)
                        }

                        FeedTabsView(
                            viewModel: viewModel.tabsViewModel,
                            container: container,
                            areChipsPinned: $areChipsPinned,
                            scrollProxy: proxy,
                            viewportHeight: visibleHeight,
                            scrollTarget: viewModel.scrollTarget(viewportHeight: visibleHeight),
                            onChipsHeightChange: { detentReporting?.report(tabChips: $0) }
                        )
                        .frame(minHeight: visibleHeight, alignment: .top)
                    }
                    .background(alignment: .top) {
                        Color.clear
                            .frame(height: FeedConstants.scrollAnchorHeight)
                            .id(FeedConstants.contentAnchorID)
                    }
                    .onGeometryChange(
                        for: CGFloat.self,
                        of: { -$0.frame(in: .named(FeedConstants.scrollCoordinateSpace)).minY },
                        action: weakify(viewModel, forFunction: FeedViewModel.scrollOffsetDidChange)
                    )
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: FeedConstants.scrollCoordinateSpace)
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear
                        .frame(height: FeedConstants.searchContentInset)
                        .allowsHitTesting(false)
                }
                .reverseMask(alignment: .top) {
                    if viewModel.isContentUnderSearchBar, !areChipsPinned {
                        FeedTopFade()
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

        withAnimation(reduceMotion ? nil : .default) {
            viewModel.resetScroll()
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
