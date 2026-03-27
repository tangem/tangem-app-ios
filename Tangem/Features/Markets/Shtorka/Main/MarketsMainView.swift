//
//  MarketsMainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation
import TangemAccessibilityIdentifiers

struct MarketsMainView: View {
    @ObservedObject var viewModel: MarketsMainViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver
    @Injected(\.overlayContentContainer) private var overlayContentContainer: OverlayContentContainer

    @State private var headerHeight: CGFloat = .zero
    @State private var defaultListOverlayTotalHeight: CGFloat = .zero
    @State private var searchResultListOverlayTotalHeight: CGFloat = .zero
    @State private var listOverlayVerticalOffset: CGFloat = .zero
    @State private var listOverlayTitleOpacity: CGFloat = 1.0
    @State private var isListContentObscured = false

    private var defaultBackgroundColor: Color {
        if FeatureProvider.isAvailable(.redesign) {
            .Tangem.Surface.level2
        } else {
            Colors.Background.tertiary
        }
    }

    private let scrollTopAnchorId = UUID()
    private let scrollViewFrameCoordinateSpaceName = UUID()

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
                    widgetsListView
                }
            }
            .opacity(viewModel.overlayContentHidingProgress) // Hides list content on bottom sheet minimizing
            .scrollDismissesKeyboard(.immediately)

            navigationBarBackground

            MainBottomSheetHeaderView(viewModel: viewModel.headerViewModel)
                .readGeometry(\.size.height, bindTo: $headerHeight)
                .infinityFrame(axis: .vertical, alignment: .top)
        }
        .background(defaultBackgroundColor.ignoresSafeArea())
        // This dummy title won't be shown in the UI, but it's required since without it UIKit will allocate
        // another `UINavigationBar` instance for use on the `Markets Token Details` page, and the code inside
        // `navigationControllerConfigurator` won't hide the navigation bar on that page (`Markets Token Details`)
        .navigationTitle("MarketsMainView")
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

    @ViewBuilder
    private var searchResultView: some View {
        switch viewModel.tokenListViewModel.tokenListLoadingState {
        case .noResults:
            noResultsStateView
        case .error:
            errorStateView(with: viewModel.tokenListViewModel.onTryLoadList)
        case .loading, .allDataLoaded, .idle:
            MarketsMainSearchView(
                headerHeight: headerHeight,
                scrollTopAnchorId: scrollTopAnchorId,
                scrollViewFrameCoordinateSpaceName: scrollViewFrameCoordinateSpaceName,
                searchResultListOverlayTotalHeight: searchResultListOverlayTotalHeight,
                mainWindowSize: mainWindowSize,
                updateListOverlayAppearance: updateListOverlayAppearance(contentOffset:),
                viewModel: viewModel.tokenListViewModel
            )
        }
    }

    private var defaultListOverlay: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center, spacing: .zero) {
                if FeatureProvider.isAvailable(.redesign) {
                    redesignTitleView
                } else {
                    legacyTitleView
                }

                Spacer()
            }
        }
        .infinityFrame(axis: .horizontal)
        .padding(.top, Layout.listOverlayTopInset)
        .padding(.bottom, Layout.listOverlayBottomInset)
        .padding(.horizontal, Layout.defaultHorizontalInset)
        .padding(.horizontal, Layout.Header.defaultHorizontalInset)
        .readGeometry(\.size.height, bindTo: $defaultListOverlayTotalHeight)
    }

    private func titleView(titleFont: Font, titleColor: Color, dateFont: Font, dateColor: Color) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(viewModel.headerTitle)
                .style(titleFont, color: titleColor)
                .opacity(listOverlayTitleOpacity)

            Text(viewModel.headerDate)
                .style(dateFont, color: dateColor)
                .opacity(listOverlayTitleOpacity)
        }
    }

    private var legacyTitleView: some View {
        titleView(
            titleFont: Fonts.Bold.title1, titleColor: Colors.Text.primary1,
            dateFont: Fonts.Bold.title1, dateColor: Colors.Text.tertiary
        )
    }

    private var redesignTitleView: some View {
        titleView(
            titleFont: Font.Tangem.Heading28.regular, titleColor: Color.Tangem.Text.Neutral.primary,
            dateFont: Font.Tangem.Heading28.regular, dateColor: Color.Tangem.Text.Neutral.tertiary
        )
    }

    // MARK: - Helpers

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
                defaultListOverlayTotalHeight - Layout.listOverlayBottomInset,
                .zero
            )
            offSet = clamp(contentOffset.y, min: .zero, max: maxOffset)
        }

        listOverlayTitleOpacity = maxOffset.isZero ? 1.0 : 1.0 - offSet / maxOffset // Division by zero protection
        listOverlayVerticalOffset = -offSet
        isListContentObscured = contentOffset.y >= (maxOffset + Layout.listOverlayBottomInset)
    }

    // MARK: - Widgets Implementation

    @ViewBuilder
    private var widgetsListView: some View {
        ZStack {
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

                        if case .present(let widgetItems) = viewModel.widgetsViewState {
                            VStack(alignment: .leading, spacing: Layout.Widgets.verticalContentSpacing) {
                                ForEach(widgetItems, id: \.id) { item in
                                    makeContentView(with: item.content)
                                }
                            }
                        }
                    }
                    .padding(.top, Layout.Widgets.topPadding)
                    .readContentOffset(
                        inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName),
                        onChange: updateListOverlayAppearance(contentOffset:)
                    )
                }
                .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
            }

            if case .error = viewModel.widgetsViewState {
                errorStateView(with: viewModel.onTryLoadAgain)
            }
        }
    }

    private var noResultsStateView: some View {
        MarketsNoResultsStateView()
    }

    @ViewBuilder
    private func errorStateView(with tryLoadAgain: @escaping () -> Void) -> some View {
        if FeatureProvider.isAvailable(.redesign) {
            redesignErrorStateView(with: tryLoadAgain)
        } else {
            MarketsListErrorView(tryLoadAgain: tryLoadAgain)
        }
    }

    private func redesignErrorStateView(with tryLoadAgain: @escaping () -> Void) -> some View {
        VStack(spacing: SizeUnit.x2.value) {
            Text(Localization.marketsLoadingErrorTitle)
                .style(Font.Tangem.Body14.regular, color: Color.Tangem.Text.Neutral.tertiary)

            TangemButton(content: .text(AttributedString(Localization.tryToLoadDataAgainButtonTitle)), action: tryLoadAgain)
                .setSize(.x8)
                .setCornerStyle(.rounded)
                .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.retryButton)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func makeContentView(with item: MarketsMainViewModel.WidgetContentItem) -> some View {
        if FeatureProvider.isAvailable(.redesign) {
            makeRedesignContentView(with: item)
        } else {
            makeLegacyContentView(with: item)
        }
    }

    @ViewBuilder
    private func makeLegacyContentView(with item: MarketsMainViewModel.WidgetContentItem) -> some View {
        switch item {
        case .top(let viewModel):
            TopMarketWidgetView(viewModel: viewModel)
        case .pulse(let viewModel):
            PulseMarketWidgetView(viewModel: viewModel)
        case .news(let viewModel):
            NewsWidgetView(viewModel: viewModel)
        case .earn(let viewModel):
            EarnWidgetView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func makeRedesignContentView(with item: MarketsMainViewModel.WidgetContentItem) -> some View {
        switch item {
        case .top(let viewModel):
            TopMarketWidgetViewRedesign(viewModel: viewModel)
        case .pulse(let viewModel):
            PulseMarketWidgetViewRedesign(viewModel: viewModel)
        case .news(let viewModel):
            NewsWidgetViewRedesign(viewModel: viewModel)
        case .earn(let viewModel):
            EarnWidgetViewRedesign(viewModel: viewModel)
        }
    }
}

// MARK: - Layout

private extension MarketsMainView {
    enum Layout {
        static let defaultHorizontalInset = 16.0
        static let listOverlayTopInset = 16.0
        static let listOverlayBottomInset = 0.0

        enum Header {
            static let defaultHorizontalInset = 4.0
        }

        enum Widgets {
            static let verticalContentSpacing: CGFloat = 40.0
            static let topPadding: CGFloat = 32.0
        }
    }
}
