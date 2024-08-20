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

    @Environment(\.overlayContentContainer) private var overlayContentContainer

    @StateObject private var navigationControllerConfigurator = MarketsViewNavigationControllerConfigurator()

    @State private var overlayContentProgress: CGFloat = .zero
    @State private var defaultListOverlayTotalHeight: CGFloat = .zero
    @State private var defaultListOverlayRatingHeaderHeight: CGFloat = .zero
    @State private var searchResultListOverlayTotalHeight: CGFloat = .zero
    @State private var listOverlayVerticalOffset: CGFloat = .zero
    @State private var isListOverlayShadowLineViewVisible = false
    @State private var responderChainIntrospectionTrigger = UUID()

    private let scrollTopAnchorId = UUID()
    private let scrollViewFrameCoordinateSpaceName = UUID()

    private var showSearchResult: Bool { viewModel.isSearching }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if showSearchResult {
                searchResultView
            } else {
                defaultMarketsView
            }
        }
        .scrollDismissesKeyboardCompat(.immediately)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .background(Colors.Background.primary)
        // This dummy title won't be shown in the UI, but it's required since without it UIKit will allocate
        // another `UINavigationBar` instance for use on the `Markets Token Details` page, and the code below
        // (`navigationController.navigationBar.isHidden = true`) won't hide the navigation bar on that page
        // (`Markets Token Details`).
        .navigationTitle("Markets")
        .navigationBarTitleDisplayMode(.inline)
        .onWillAppear {
            navigationControllerConfigurator.setCornerRadius(overlayContentContainer.cornerRadius)
            // `UINavigationBar` may be installed into the view hierarchy quite late;
            // therefore, we're triggering introspection in the `viewWillAppear` callback
            responderChainIntrospectionTrigger = UUID()
        }
        .onAppear {
            navigationControllerConfigurator.setCornerRadius(overlayContentContainer.cornerRadius)
            // `UINavigationBar` may be installed into the view hierarchy quite late;
            // therefore, we're triggering introspection in the `onAppear` callback
            responderChainIntrospectionTrigger = UUID()
        }
        .introspectResponderChain(
            introspectedType: UINavigationController.self,
            updateOnChangeOf: responderChainIntrospectionTrigger,
            action: navigationControllerConfigurator.configure(_:)
        )
        .onOverlayContentProgressChange { progress in
            overlayContentProgress = progress
        }
    }

    @ViewBuilder
    private var defaultMarketsView: some View {
        list
            .safeAreaInset(edge: .top, spacing: 0.0) {
                defaultListOverlay
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
            list
                .safeAreaInset(edge: .top, spacing: 0.0) {
                    searchResultListOverlay
                }
                .overlay(alignment: .top) {
                    listOverlaySeparator
                }
        }
    }

    @ViewBuilder
    private var defaultListOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsCommonTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)

            MarketsRatingHeaderView(viewModel: viewModel.marketsRatingHeaderViewModel)
                .readGeometry(\.size.height, bindTo: $defaultListOverlayRatingHeaderHeight)
        }
        .infinityFrame(axis: .horizontal)
        .padding(.top, Constants.listOverlayTopInset)
        .padding(.bottom, Constants.listOverlayBottomInset)
        .padding(.horizontal, 16)
        .background(Colors.Background.primary)
        .overlay(alignment: .bottom) {
            listOverlaySeparator
        }
        .readGeometry(\.size.height, bindTo: $defaultListOverlayTotalHeight)
        .offset(y: listOverlayVerticalOffset)
    }

    @ViewBuilder
    private var searchResultListOverlay: some View {
        Text(Localization.marketsSearchResultTitle)
            .style(Fonts.Bold.title3, color: Colors.Text.primary1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Constants.listOverlayTopInset)
            .padding(.horizontal, 16)
            .background(Colors.Background.primary)
            .readGeometry(\.size.height, bindTo: $searchResultListOverlayTotalHeight)
            .offset(y: listOverlayVerticalOffset)
    }

    @ViewBuilder
    private var listOverlaySeparator: some View {
        Separator(color: Colors.Stroke.primary)
            .hidden(!isListOverlayShadowLineViewVisible)
    }

    @ViewBuilder
    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                // ScrollView inserts default spacing between its content views.
                // Wrapping content into a `VStack` prevents it.
                VStack(spacing: 0.0) {
                    Color.clear.frame(height: 0)
                        .id(scrollTopAnchorId)

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
                        proxy.scrollTo(scrollTopAnchorId)
                    }
                }
                .readContentOffset(
                    inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName),
                    onChange: updateListOverlayAppearance(contentOffset:)
                )
            }
            .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
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
            isButtonBusy: viewModel.isDataProviderBusy,
            retryButtonAction: viewModel.onTryLoadList
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }

    private func updateListOverlayAppearance(contentOffset: CGPoint) {
        guard abs(1.0 - overlayContentProgress) <= .ulpOfOne else {
            listOverlayVerticalOffset = .zero
            isListOverlayShadowLineViewVisible = false
            return
        }

        let maxOffset: CGFloat
        let offSet: CGFloat

        if showSearchResult {
            maxOffset = searchResultListOverlayTotalHeight
            offSet = -clamp(contentOffset.y, min: .zero, max: maxOffset)
        } else {
            maxOffset = max(
                defaultListOverlayTotalHeight - defaultListOverlayRatingHeaderHeight - Constants.listOverlayBottomInset,
                .zero
            )
            offSet = -clamp(contentOffset.y, min: .zero, max: maxOffset)
        }

        listOverlayVerticalOffset = offSet
        isListOverlayShadowLineViewVisible = contentOffset.y >= (maxOffset + Constants.listOverlayBottomInset)
    }
}

// MARK: - Constants

private extension MarketsView {
    enum Constants {
        static let listOverlayTopInset = /* 10.0 */ 18.0 // Temporarily increased until fade in/out logic is implemented ([REDACTED_INFO])
        static let listOverlayBottomInset = 12.0
    }
}

// MARK: - Auxiliary types

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
