//
//  MarketsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

struct MarketsView: View {
    @ObservedObject var viewModel: MarketsViewModel

    @State private var introspectResponderChainId = UUID()

    private let scrollTopAnchorID = "markets_scroll_view_top_anchor_id"

    var body: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.isSearching {
                searchResultView
            } else {
                defaultMarketsView
            }
        }
        .scrollDismissesKeyboardCompat(.immediately)
        .background(Colors.Background.primary)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .background(Colors.Background.primary)
        // This dummy title won't be shown in the UI, but it's required since without it UIKit will allocate
        // another `UINavigationBar` instance for use on the `Markets Token Details` page, and the code below
        // (`navigationController.navigationBar.isHidden = true`) won't hide the navigation bar on that page
        // (`Markets Token Details`).
        .navigationTitle("Markets")
        .navigationBarTitleDisplayMode(.inline)
        .onWillAppear {
            // `UINavigationBar` can be installed into the view hierarchy quite late;
            // therefore, we're triggering introspection in the `viewWillAppear` callback
            introspectResponderChainId = UUID()
        }
        .introspectResponderChain(
            introspectedType: UINavigationController.self,
            updateOnChangeOf: introspectResponderChainId
        ) { navigationController in
            // Unlike `UINavigationController.setNavigationBarHidden(_:animated:)` from UIKit and `navigationBarHidden(_:)`
            // from SwiftUI, this approach will hide the navigation bar without breaking the swipe-to-pop gesture
            navigationController.navigationBar.isHidden = true
        }
    }

    @ViewBuilder
    private var defaultMarketsView: some View {
        list
            .safeAreaInset(edge: .top, spacing: 0.0) {
                listOverlay
            }

        if case .error = viewModel.tokenListLoadingState {
            errorStateView
        }
    }

    private var loadingSkeletons: some View {
        ForEach(0 ..< 20) { _ in
            MarketsSkeletonItemView()
        }
    }

    @ViewBuilder
    private var searchResultView: some View {
        switch viewModel.tokenListLoadingState {
        case .noResults:
            noResultsStateView
        case .error:
            errorStateView
        case .loading, .allDataLoaded, .idle:
            VStack(spacing: 12) {
                Text(Localization.marketsSearchResultTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                list
            }
        }
    }

    @ViewBuilder
    private var listOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsCommonTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)

            MarketsRatingHeaderView(viewModel: viewModel.marketsRatingHeaderViewModel)
        }
        .infinityFrame(axis: .horizontal)
        .padding(.horizontal, 16)
        .padding(.bottom, 12.0)
        .background(Colors.Background.primary)
    }

    @ViewBuilder
    private var list: some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { proxy in
                // ScrollView inserts default spacing between its content views.
                // Wrapping content into a `VStack` prevents it.
                VStack(spacing: 0.0) {
                    Color.clear.frame(height: 0)
                        .id(scrollTopAnchorID)

                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.tokenViewModels) {
                            MarketsItemView(viewModel: $0)
                        }

                        // Need for display list skeleton view
                        if case .loading = viewModel.tokenListLoadingState {
                            loadingSkeletons
                        }

                        if viewModel.shouldDisplayShowTokensUnderCapView {
                            showTokensUnderCapView
                        }
                    }
                    .onReceive(viewModel.resetScrollPositionPublisher) { _ in
                        proxy.scrollTo(scrollTopAnchorID)
                    }
                }
            }
        }
    }

    private var showTokensUnderCapView: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: .zero) {
                Text(Localization.marketsSearchSeeTokensUnder100k)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            HStack(spacing: .zero) {
                Button(action: {
                    viewModel.onShowUnderCapAction()
                }, label: {
                    HStack(spacing: .zero) {
                        Text(Localization.marketsSearchShowTokens)
                            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                    }
                })
                .roundedBackground(with: Colors.Button.secondary, verticalPadding: 8, horizontalPadding: 14, radius: 10)
            }
        }
        .padding(.vertical, 12)
    }

    private var noResultsStateView: some View {
        Text(Localization.marketsSearchTokenNoResultTitle)
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
    }

    private var errorStateView: some View {
        MarketsUnableToLoadDataView(
            isButtonBusy: viewModel.tokenListLoadingState == .loading,
            retryButtonAction: viewModel.onTryLoadList
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

extension MarketsView {
    enum ListLoadingState: String, Identifiable, Hashable {
        case noResults
        case error
        case loading
        case allDataLoaded
        case idle

        var id: String { rawValue }
    }
}
