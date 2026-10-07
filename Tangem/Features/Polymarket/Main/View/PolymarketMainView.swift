//
//  PolymarketMainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPolymarketUI
import TangemUI
import TangemLocalization
import TangemUIUtils

struct PolymarketMainView: View {
    @ObservedObject var viewModel: PolymarketMainViewModel
    let balanceBlock: PolymarketBalanceBlockViewModel
    let positionsBlock: PolymarketPositionsBlockViewModel
    let searchBlock: PolymarketSearchBlockViewModel

    @State private var navBarHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            topBar

            PolymarketSearchBlockView(viewModel: searchBlock)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { PolymarketSearchFieldView(viewModel: searchBlock) }
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
            leftButtons: { NavigationBarButton.back { viewModel.handleViewAction(.close) } },
            rightButtons: {
                PolymarketOverflowMenu(
                    onHowItWorks: { viewModel.handleViewAction(.openHowItWorks) },
                    onSupportChat: { viewModel.handleViewAction(.openSupportChat) }
                )
            }
        )
        .environment(\.isRedesign, true)
    }

    private var titleView: some View {
        VStack(spacing: 2) {
            Text(Localization.predictionMainTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.predictionMainSubtitle)
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

    private var header: some View {
        VStack(spacing: 0) {
            PolymarketBalanceBlockView(viewModel: balanceBlock)

            if viewModel.isRegionRestricted {
                regionRestrictionBanner
                    .padding(.top, Constants.bannerTopSpacing)
            }

            if viewModel.isAwaitingFunds {
                PolymarketOrderNotificationsView(notifications: [.awaitingFunds])
                    .padding(.horizontal, Constants.horizontalPadding)
                    .padding(.top, Constants.bannerTopSpacing)
            }

            PolymarketPositionsBlockView(viewModel: positionsBlock)

            exploreEventsTitle
                .padding(.top, Constants.headerSpacing)
        }
        .padding(.top, Constants.headerTopPadding)
    }

    private var regionRestrictionBanner: some View {
        MessageBanner(
            title: AttributedString(Localization.predictionRegionRestrictionsTitle),
            description: AttributedString(Localization.predictionRegionRestrictionsSubtitle)
        )
        .variant(.warning)
        .glowRing(.warning)
        .slotEnd { bannerInfoIcon }
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private var bannerInfoIcon: some View {
        DesignSystem.Icons.Info.regular20.image
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: Constants.bannerIconSide))
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .accessibilityHidden(true)
    }

    private var exploreEventsTitle: some View {
        Text(Localization.predictionMainExploreEvents)
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
                    .readGeometry(inCoordinateSpace: .named(Constants.scrollSpace)) { viewModel.handleViewAction(.onTabsMove(minY: $0.frame.minY, navBarHeight: navBarHeight)) }
                    .opacity(viewModel.isTabsPinned ? 0 : 1)
                    .allowsHitTesting(!viewModel.isTabsPinned)

                eventsSection
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: navBarHeight)
        }
        .coordinateSpace(name: Constants.scrollSpace)
        .refreshable { await viewModel.refresh() }
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
                .contentShape(.rect)
                .onTapGesture { viewModel.handleViewAction(.openEventDetails(id: model.id)) }
                .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    private var failedState: some View {
        PolymarketEmptyMessageView(message: Localization.predictionMainEventsLoadError, onRetry: { viewModel.handleViewAction(.retryEvents) })
    }

    private var noResultsState: some View {
        Text(Localization.predictionMainEmptyEvents)
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

    private var paginationTrigger: some View {
        paginationLoader
            .onAppear { viewModel.handleViewAction(.loadNextPage) }
    }

    private var paginationLoader: some View {
        Loader()
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.paginationVerticalPadding)
    }

    private var paginationRetry: some View {
        TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: { viewModel.handleViewAction(.retryNextPage) })
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

        static let headerTopPadding: CGFloat = 56
        static let headerSpacing: CGFloat = 40
        static let bannerTopSpacing: CGFloat = 24
        static let bannerIconSide: CGFloat = 20

        static let eventsPlaceholderMinHeight: CGFloat = 320
    }
}
