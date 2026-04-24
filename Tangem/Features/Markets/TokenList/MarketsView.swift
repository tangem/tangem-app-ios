//
//  MarketsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemMacro
import TangemUI
import TangemUIUtils

struct MarketsView: View {
    @ObservedObject var viewModel: MarketsViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver
    @Injected(\.overlayContentContainer) private var overlayContentContainer: OverlayContentContainer

    @State private var headerHeight: CGFloat = .zero
    @State private var defaultListOverlayTotalHeight: CGFloat = .zero
    @State private var defaultListOverlayRatingHeaderHeight: CGFloat = .zero
    @State private var searchResultListOverlayTotalHeight: CGFloat = .zero
    @State private var listOverlayVerticalOffset: CGFloat = .zero
    @State private var listOverlayTitleOpacity: CGFloat = 1.0
    @State private var isListContentObscured = false

    private var defaultBackgroundColor: Color { Colors.Background.primary }

    private var overlayHeight: CGFloat { showSearchResult ? searchResultListOverlayTotalHeight : defaultListOverlayTotalHeight }
    private var showSearchResult: Bool { viewModel.isSearching }

    var body: some View {
        rootView
            .onAppear {
                viewModel.onViewAppear()
            }
            .onDisappear(perform: viewModel.onViewDisappear)
            .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)

                if progress < 1 {
                    UIResponder.current?.resignFirstResponder()
                }
            }
            .onOverlayContentStateChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] state in
                viewModel?.onOverlayContentStateChange(state)
            }
    }

    private var rootView: some View {
        ZStack {
            Group {
                if showSearchResult {
                    searchResultView
                } else {
                    defaultMarketsView
                }
            }
            .opacity(viewModel.overlayContentHidingProgress) // Hides list content on bottom sheet minimizing
            .scrollDismissesKeyboard(.immediately)

            navigationBarBackground

            MainBottomSheetHeaderView(viewModel: viewModel.headerViewModel)
                .readGeometry(\.size.height, bindTo: $headerHeight)
                .infinityFrame(axis: .vertical, alignment: .top)
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
        .background(defaultBackgroundColor.ignoresSafeArea())
        // This dummy title won't be shown in the UI, but it's required since without it UIKit will allocate
        // another `UINavigationBar` instance for use on the `Markets Token Details` page, and the code inside
        // `navigationControllerConfigurator` won't hide the navigation bar on that page (`Markets Token Details`)
        .navigationTitle("Markets")
        .navigationBarTitleDisplayMode(.inline)
        .injectMarketsNavigationConfigurator()
    }

    private var navigationBarBackground: some View {
        MarketsNavigationBarBackgroundView(
            backdropViewColor: defaultBackgroundColor,
            overlayContentHidingProgress: viewModel.overlayContentHidingProgress,
            isNavigationBarBackgroundBackdropViewHidden: viewModel.isNavigationBarBackgroundBackdropViewHidden,
            isListContentObscured: isListContentObscured
        ) {
            if showSearchResult {
                searchResultListOverlay
            } else {
                defaultListOverlay
            }
        }
        .frame(height: headerHeight + overlayHeight)
        .offset(y: listOverlayVerticalOffset)
        .infinityFrame(axis: .vertical, alignment: .top)
    }

    @ViewBuilder
    private var defaultMarketsView: some View {
        list

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
        }
    }

    private var defaultListOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsCommonTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .opacity(listOverlayTitleOpacity)

            MarketsRatingHeaderView(viewModel: viewModel.marketsRatingHeaderViewModel)
                .readGeometry(\.size.height, bindTo: $defaultListOverlayRatingHeaderHeight)
        }
        .infinityFrame(axis: .horizontal)
        .padding(.top, Constants.listOverlayTopInset)
        .padding(.bottom, Constants.listOverlayBottomInset)
        .padding(.horizontal, Constants.defaultHorizontalInset)
        .readGeometry(\.size.height, bindTo: $defaultListOverlayTotalHeight)
    }

    private var searchResultListOverlay: some View {
        Text(Localization.marketsSearchResultTitle)
            .style(Fonts.Bold.title3, color: Colors.Text.primary1)
            .opacity(listOverlayTitleOpacity)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Constants.listOverlayTopInset)
            .padding(.horizontal, Constants.defaultHorizontalInset)
            .readGeometry(\.size.height, bindTo: $searchResultListOverlayTotalHeight)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                // ScrollView inserts default spacing between its content views.
                // Wrapping content into a `VStack` prevents it.
                VStack(spacing: 0.0) {
                    Color.clear
                        .frame(height: 0)
                        .id(Identifiers.scrollTopAnchorID)

                    // Using plain old overlay + dummy `Color.clear` spacer in the scroll view due to the buggy
                    // `safeAreaInset(edge:alignment:spacing:content:)` iOS 15+ API which has both layout and touch-handling issues
                    Color.clear
                        .frame(height: headerHeight)

                    // Using plain old overlay + dummy `Color.clear` spacer in the scroll view due to the buggy
                    // `safeAreaInset(edge:alignment:spacing:content:)` iOS 15+ API which has both layout and touch-handling issues
                    Color.clear
                        .frame(height: overlayHeight)

                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.tokenViewModels) {
                            MarketsItemView(viewModel: $0, cellWidth: mainWindowSize.width)
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
                        proxy.scrollTo(Identifiers.scrollTopAnchorID)
                    }
                }
                .readContentOffset(
                    inCoordinateSpace: .named(CoordinateSpaceName.scrollViewFrame),
                    onChange: updateListOverlayAppearance(contentOffset:)
                )
            }
            .coordinateSpace(name: CoordinateSpaceName.scrollViewFrame)
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
                .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsTokensUnderCapExpandButton)
                .roundedBackground(with: Colors.Button.secondary, verticalPadding: 8, horizontalPadding: 14, radius: 10)
            }
        }
        .padding(.vertical, 12)
    }

    private var noResultsStateView: some View {
        Text(Localization.marketsSearchTokenNoResultTitle)
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSearchNoResultsLabel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Constants.defaultHorizontalInset)
    }

    private var errorStateView: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: viewModel.onTryLoadList
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Constants.defaultHorizontalInset)
    }

    private func updateListOverlayAppearance(contentOffset: CGPoint) {
        // Early exit to prevent list overlay 'jiggling' due to small fluctuations of content offset while dragging the list
        if overlayContentContainer.isScrollViewLocked {
            listOverlayVerticalOffset = .zero
            listOverlayTitleOpacity = 1.0
            isListContentObscured = false
            return
        }

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
            offSet = clamp(contentOffset.y, min: .zero, max: maxOffset)
        }

        listOverlayTitleOpacity = maxOffset.isZero ? 1.0 : 1.0 - offSet / maxOffset // Division by zero protection
        listOverlayVerticalOffset = -offSet
        isListContentObscured = contentOffset.y >= (maxOffset + Constants.listOverlayBottomInset)
    }
}

// MARK: - Constants

private extension MarketsView {
    enum Constants {
        static let defaultHorizontalInset = 16.0
        static let listOverlayTopInset = 10.0
        static let listOverlayBottomInset = 12.0
    }

    enum Identifiers {
        private static let prefix = "MarketsView.Identifiers."

        static let scrollTopAnchorID = prefix + "scrollTopAnchorID"
    }

    enum CoordinateSpaceName {
        private static let prefix = "MarketsView.CoordinateSpaceName."

        static let scrollViewFrame = prefix + "scrollViewFrame"
    }
}

// MARK: - Auxiliary types

extension MarketsView {
    @CaseFlagable
    enum ListLoadingState: String, Identifiable, Hashable {
        case noResults
        case error
        case loading
        case allDataLoaded
        case idle

        var id: String { rawValue }
    }
}
