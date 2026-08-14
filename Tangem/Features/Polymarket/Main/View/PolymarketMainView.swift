//
//  PolymarketMainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemPolymarket

struct PolymarketMainView: View {
    @ObservedObject var viewModel: PolymarketMainViewModel

    @State private var navBarHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            topBar
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 0) {
            navigationBar
                .padding(.top, Constants.navBarTopPadding)
                .readGeometry(\.size.height, bindTo: $navBarHeight)

            if viewModel.isTabsPinned {
                tabsRow
            }
        }
        .background {
            Fade(position: .top)
                .blurred()
                .backgroundColor(DesignSystem.Color.bgPrimary)
                .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: - Navbar

    private var navigationBar: some View {
        NavigationBar(
            settings: .init(backgroundColor: .clear, horizontalPadding: Constants.horizontalPadding, height: Constants.navBarSettingsHeight),
            titleView: { titleView },
            leftButtons: { NavigationBarButton.back { viewModel.dismiss() } },
            rightButtons: { NavigationBarButton.details {} }
        )
        .environment(\.isRedesign, true)
    }

    private var titleView: some View {
        VStack(spacing: 2) {
            // [REDACTED_TODO_COMMENT]
            Text("Predictions")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Text("USDC on Polygon network")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }

    // MARK: - Tabs

    @ViewBuilder
    private var tabsRow: some View {
        if showsTabs {
            tabs
                .padding(.vertical, Constants.tabsVerticalPadding)
        }
    }

    private var showsTabs: Bool {
        !viewModel.categories.isEmpty || viewModel.loadingState == .loading
    }

    @ViewBuilder
    private var tabs: some View {
        if viewModel.categories.isEmpty {
            PolymarketCategoriesSkeletonView()
        } else {
            categoriesTabs
        }
    }

    private var categoriesTabs: some View {
        TabNavigation(data: viewModel.categoryTabs, selection: viewModel.selectedCategoryTab)
            .variant(.material)
            .scrollable()
    }

    // MARK: - Balance

    // [REDACTED_TODO_COMMENT]
    private var header: some View {
        VStack(spacing: Constants.headerSpacing) {
            balanceBlock

            exploreEventsTitle
        }
        .padding(.top, Constants.headerTopPadding)
    }

    private var balanceBlock: some View {
        VStack(spacing: Constants.balanceSpacing) {
            balanceSelector

            // [REDACTED_TODO_COMMENT]
            Text("$0.00")
                .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)

            actionButtons
                .padding(.top, Constants.actionButtonsTopPadding)
        }
        .frame(maxWidth: .infinity)
    }

    private var balanceSelector: some View {
        HStack(spacing: Constants.balanceSelectorSpacing) {
            // [REDACTED_TODO_COMMENT]
            Text("Total Balance")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

            Assets.DesignSystem.chevronDown.image
                .renderingMode(.template)
                .resizable()
                .frame(width: Constants.selectorIconSize, height: Constants.selectorIconSize)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Constants.actionButtonsSpacing) {
            // [REDACTED_TODO_COMMENT]
            TangemMainActionButton(title: "Add funds", icon: Assets.DesignSystem.arrowDown) {}

            // [REDACTED_TODO_COMMENT]
            TangemMainActionButton(title: "Withdraw", icon: Assets.DesignSystem.arrowUp) {}
                .disabled(true)
        }
    }

    private var exploreEventsTitle: some View {
        // [REDACTED_TODO_COMMENT]
        Text("Explore Events")
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.horizontalPadding)
    }

    // MARK: - List

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: Constants.contentSpacing) {
                header

                tabsRow
                    .readGeometry(inCoordinateSpace: .named(Constants.scrollSpace)) { viewModel.updatePinnedState(tabsMinY: $0.frame.minY, navBarHeight: navBarHeight) }
                    .opacity(viewModel.isTabsPinned ? 0 : 1)
                    .allowsHitTesting(!viewModel.isTabsPinned)

                eventsSection
            }
            .padding(.top, navBarHeight)
        }
        .coordinateSpace(name: Constants.scrollSpace)
    }

    @ViewBuilder
    private var eventsSection: some View {
        switch viewModel.loadingState {
        case .loading:
            PolymarketEventsSkeletonView()
        case .error:
            failedState
        case .noResults:
            noResultsState
        default:
            eventCards
            paginationFooter
        }
    }

    private var eventCards: some View {
        ForEach(viewModel.eventCards, id: \.id) { model in
            PolymarketEventCard(model: model)
                .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    private var failedState: some View {
        // [REDACTED_TODO_COMMENT]
        PolymarketEmptyMessageView(message: "Failed to load events.\nTap to reload", onRetry: viewModel.load)
    }

    private var noResultsState: some View {
        // [REDACTED_TODO_COMMENT]
        Text("No available data")
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Constants.eventsPlaceholderMinHeight)
    }

    @ViewBuilder
    private var paginationFooter: some View {
        switch viewModel.loadingState {
        case .loaded:
            paginationTrigger
        case .paginationLoading:
            paginationLoader
        case .paginationError:
            paginationRetry
        case .loading, .error, .noResults, .allDataLoaded:
            EmptyView()
        }
    }

    /// Only the settled state carries the trigger: while a page is in flight the loader below takes its place,
    /// so `onAppear` cannot fire a second request.
    private var paginationTrigger: some View {
        paginationLoader
            .onAppear { viewModel.loadMore() }
    }

    private var paginationLoader: some View {
        Loader()
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.paginationVerticalPadding)
    }

    private var paginationRetry: some View {
        TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.loadMore)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.paginationVerticalPadding)
    }
}

extension PolymarketMainView {
    enum Constants {
        static let scrollSpace = "PolymarketMainScroll"

        static let contentSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let navBarTopPadding: CGFloat = 8
        static let navBarSettingsHeight: CGFloat = 56
        static let tabsVerticalPadding: CGFloat = 8
        static let paginationVerticalPadding: CGFloat = 20

        static let headerTopPadding: CGFloat = 24
        static let headerSpacing: CGFloat = 40
        static let balanceSpacing: CGFloat = 4
        static let balanceSelectorSpacing: CGFloat = 4
        static let selectorIconSize: CGFloat = 20
        static let actionButtonsSpacing: CGFloat = 24
        static let actionButtonsTopPadding: CGFloat = 20

        static let eventsPlaceholderMinHeight: CGFloat = 320
    }
}
