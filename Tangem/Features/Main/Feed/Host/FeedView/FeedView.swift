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
        VStack(spacing: Constants.headerSpacing) {
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
            shtorkaStateObject: shtorkaStateObject,
            isActive: searchViewModel.isActive,
            onFocus: searchViewModel.open,
            onCancel: searchViewModel.reset
        )
    }

    private var feedScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Constants.sectionSpacing) {
                    FeedWidgetsView(viewModel: viewModel.widgetsViewModel)
                        .padding(.top, Constants.widgetsTopInset)
                        .readGeometry(\.size.height) { shtorkaStateObject.report(widgets: $0) }

                    FeedTabsView(
                        viewModel: viewModel.tabsViewModel,
                        shtorkaStateObject: shtorkaStateObject,
                        onSwitchTab: { scrollToTop(with: proxy) }
                    )
                }
                .id(FeedConstants.contentAnchorID)
            }
            .scrollIndicators(.hidden)
            .onChange(of: shtorkaStateObject.size) { size in
                resetScroll(at: size, with: proxy)
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

    private func scrollToTop(with proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(FeedConstants.contentAnchorID, anchor: .top)
        }
    }
}

// MARK: - Constants

private extension FeedView {
    enum Constants {
        static let headerSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 20
        static let widgetsTopInset: CGFloat = 8
        static let searchTransitionDuration: TimeInterval = 0.2
    }
}
