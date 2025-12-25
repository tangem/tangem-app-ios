//
//  MarketsSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import Combine
import BlockchainSdk
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation

struct MarketsSearchView: View {
    @ObservedObject var viewModel: MarketsSearchViewModel
    let onBackButtonAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.mainWindowSize) private var mainWindowSize

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    @State private var headerHeight: CGFloat = .zero
    @State private var isListContentObscured = false

    @State private var defaultListOverlayTotalHeight: CGFloat = .zero
    @State private var defaultListOverlayRatingHeaderHeight: CGFloat = .zero
    @State private var searchResultListOverlayTotalHeight: CGFloat = .zero
    @State private var listOverlayVerticalOffset: CGFloat = .zero
    @State private var listOverlayTitleOpacity: CGFloat = 1.0
    @State private var responderChainIntrospectionTrigger = UUID()

    @StateObject private var scrollOffsetHandler = ScrollViewOffsetHandler.marketTokenDetails(
        initialState: MarketsNavigationBarTitle.State(priceOpacity: nil, titleOffset: 0),
        labelOffset: Constants.scrollViewContentTopInset + Constants.scrollViewVerticalPadding
    )

    private let scrollTopAnchorId = UUID()
    private let scrollViewFrameCoordinateSpaceName = UUID()

    private var isDarkColorScheme: Bool { colorScheme == .dark }

    /// `UIColor` is used since `Color(uiColor:)` constructor loses Xcode color asset dark/light appearance setting.
    @available(iOS, obsoleted: 18.0, message: "Replace 'UIColor' with 'Color' since 'Color.mix(with:by:in:)' is available")
    private var defaultBackgroundColor: UIColor {
        isDarkColorScheme ? UIColor.backgroundPrimary.forcedDark : UIColor.backgroundSecondary.forcedLight
    }

    private var copyDefaultBackgroundColor: Color { Colors.Background.primary }

    /// `UIColor` is used since `Color(uiColor:)` constructor loses Xcode color asset dark/light appearance setting.
    @available(iOS, obsoleted: 18.0, message: "Replace 'UIColor' with 'Color' since 'Color.mix(with:by:in:)' is available")
    private var overlayContentHidingBackgroundColor: UIColor {
        isDarkColorScheme ? defaultBackgroundColor.forcedDark : UIColor.backgroundPlain.forcedLight
    }

    private var overlayHeight: CGFloat { showSearchResult ? searchResultListOverlayTotalHeight : defaultListOverlayTotalHeight }

    private var showSearchResult: Bool { viewModel.isSearching }

    var body: some View {
        rootView
            .onOverlayContentStateChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] state in
                viewModel?.onOverlayContentStateChange(state)
            }
            .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)
            }
            .background {
                backgroundColor
                    .ignoresSafeArea(edges: .vertical)
            }
            .onAppear(perform: scrollOffsetHandler.onViewAppear)
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            Group {
                defaultMarketsView
            }
            .opacity(viewModel.overlayContentHidingProgress) // Hides list content on bottom sheet minimizing
            .scrollDismissesKeyboard(.immediately)

            navigationBarBackground

            ZStack {
                if showSearchResult {
                    MainBottomSheetHeaderView(viewModel: viewModel.headerViewModel)
                        .readGeometry(\.size.height, bindTo: $headerHeight)
                        .infinityFrame(axis: .vertical, alignment: .top)
                        .transition(.opacity)
                } else {
                    navigationBar
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.1), value: showSearchResult)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Navigation Bar implementation

    @ViewBuilder
    private var navigationBarBackground: some View {
        MarketsNavigationBarBackgroundView(
            backdropViewColor: backgroundColor,
            overlayContentHidingProgress: viewModel.overlayContentHidingProgress,
            isNavigationBarBackgroundBackdropViewHidden: viewModel.isNavigationBarBackgroundBackdropViewHidden,
            isListContentObscured: isListContentObscured
        ) {
            Group {
                if showSearchResult {
                    MarketsSearchResultListOverlayView(
                        titleOpacity: $listOverlayTitleOpacity,
                        totalHeight: $searchResultListOverlayTotalHeight
                    )
                } else {
                    defaultListOverlay
                }
            }
        }
        .frame(height: headerHeight + overlayHeight)
        .offset(y: listOverlayVerticalOffset)
        .infinityFrame(axis: .vertical, alignment: .top)
    }

    private var navigationBar: some View {
        MarketsSearchNavigationBar(
            title: Localization.marketsCommonTitle,
            onBackButtonAction: onBackButtonAction,
            onSearchButtonAction: viewModel.onSearchButtonAction
        )
        .readGeometry(\.size.height, bindTo: $headerHeight)
        .infinityFrame(axis: .vertical, alignment: .top)
    }

    // MARK: - List Overlay

    @ViewBuilder
    private var defaultListOverlay: some View {
        VStack(alignment: .leading, spacing: .zero) {
            MarketsRatingHeaderView(viewModel: viewModel.marketsRatingHeaderViewModel)
                .readGeometry(\.size.height, bindTo: $defaultListOverlayRatingHeaderHeight)
        }
        .infinityFrame(axis: .horizontal)
        .padding(.top, Constants.listOverlayTopInset)
        .padding(.bottom, Constants.listOverlayBottomInset)
        .padding(.horizontal, Constants.defaultHorizontalInset)
        .readGeometry(\.size.height, bindTo: $defaultListOverlayTotalHeight)
    }

    // MARK: - Content Implementation

    @ViewBuilder
    private var defaultMarketsView: some View {
        list

        if case .error = viewModel.tokenListViewModel.tokenListLoadingState {
            EmptyView()
        }
    }

    @ViewBuilder
    private var backgroundColor: Color {
        let uiColor = overlayContentHidingBackgroundColor.mix(
            with: defaultBackgroundColor,
            by: viewModel.overlayContentHidingProgress
        )

        Color(uiColor: uiColor)
    }

    @ViewBuilder
    private var searchResultView: some View {
        switch viewModel.tokenListViewModel.tokenListLoadingState {
        case .noResults:
            noResultsStateView
        case .error:
            errorStateView
        case .loading, .allDataLoaded, .idle:
            list
        }
    }

    @ViewBuilder
    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                // ScrollView inserts default spacing between its content views.
                // Wrapping content into a `VStack` prevents it.
                VStack(spacing: 0.0) {
                    Color.clear
                        .frame(height: 0)
                        .id(scrollTopAnchorId)

                    // Using plain old overlay + dummy `Color.clear` spacer in the scroll view due to the buggy
                    // `safeAreaInset(edge:alignment:spacing:content:)` iOS 15+ API which has both layout and touch-handling issues
                    Color.clear
                        .frame(height: headerHeight)

                    // Using plain old overlay + dummy `Color.clear` spacer in the scroll view due to the buggy
                    // `safeAreaInset(edge:alignment:spacing:content:)` iOS 15+ API which has both layout and touch-handling issues
                    Color.clear
                        .frame(height: overlayHeight)

                    LazyVStack(spacing: 0) {
                        if !showSearchResult, viewModel.yieldModeNotificationVisible {
                            MarketsYieldModeNotificationView(
                                openAction: { [viewModel] in
                                    viewModel.openYieldModeFiter()
                                },
                                closeAction: { [viewModel] in
                                    viewModel.closeYieldModeNotification()
                                }
                            )
                        }

                        ForEach(viewModel.tokenListViewModel.tokenViewModels) {
                            MarketsItemView(viewModel: $0, cellWidth: mainWindowSize.width)
                        }

                        // Need for display list skeleton view
                        if case .loading = viewModel.tokenListViewModel.tokenListLoadingState {
                            loadingSkeletons
                        }

                        if viewModel.tokenListViewModel.shouldDisplayShowTokensUnderCapView {
                            MarketsTokensUnderCapView(onShowUnderCapAction: viewModel.tokenListViewModel.onShowUnderCapAction)
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

    private func updateListOverlayAppearance(contentOffset: CGPoint) {
        let maxOffset: CGFloat
        let offSet: CGFloat

        if showSearchResult {
            maxOffset = searchResultListOverlayTotalHeight
            offSet = clamp(contentOffset.y, min: .zero, max: maxOffset)
        } else {
            maxOffset = max(
                defaultListOverlayTotalHeight - defaultListOverlayRatingHeaderHeight - Constants.listOverlayBottomInset,
                .zero
            )
            offSet = .zero
        }

        listOverlayTitleOpacity = showSearchResult && !maxOffset.isZero ? 1.0 - offSet / maxOffset : 1.0
        listOverlayVerticalOffset = showSearchResult ? -offSet : .zero
        isListContentObscured = contentOffset.y >= (maxOffset + Constants.listOverlayBottomInset)
    }

    private var noResultsStateView: some View {
        MarketsNoResultsStateView()
    }

    private var errorStateView: some View {
        MarketsListErrorView(tryLoadAgain: viewModel.tokenListViewModel.onTryLoadList)
    }

    private var loadingSkeletons: some View {
        ForEach(0 ..< 20) { _ in
            MarketsSkeletonItemView()
        }
    }
}

// MARK: - Constants

private extension MarketsSearchView {
    enum Constants {
        static let defaultHorizontalInset = 16.0
        static let listOverlayTopInset = 10.0
        static let listOverlayBottomInset = 12.0
        static let scrollViewContentTopInset = 14.0
        static let scrollViewVerticalPadding = 16.0
        static let blockHorizontalPadding: CGFloat = 16.0
        static let contentVerticalSpacing: CGFloat = 14
    }
}

// MARK: - Auxiliary types

extension MarketsSearchView {
    enum ListLoadingState: String, Identifiable, Hashable {
        case noResults
        case error
        case loading
        case allDataLoaded
        case idle

        var id: String { rawValue }
    }
}
