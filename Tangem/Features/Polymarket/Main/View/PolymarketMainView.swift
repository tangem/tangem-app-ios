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

    @State private var navBarHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            topBar

            PolymarketSearchBlockView(viewModel: viewModel.searchViewModel)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { PolymarketSearchFieldView(viewModel: viewModel.searchViewModel) }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 0) {
            navigationBar
                .padding(.top, Constants.navBarTopPadding)
                .readGeometry(\.size.height, bindTo: $navBarHeight)

            if viewModel.isTabsPinned {
                PolymarketEventsTabsView(viewModel: viewModel.eventsViewModel)
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
            settings: .init(backgroundColor: .clear, horizontalPadding: PolymarketMainLayout.horizontalPadding, height: Constants.navBarSettingsHeight),
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

    // MARK: - Balance

    private var header: some View {
        VStack(spacing: 0) {
            PolymarketBalanceBlockView(viewModel: viewModel.balanceViewModel)

            if viewModel.isRegionRestricted {
                regionRestrictionBanner
                    .padding(.top, Constants.bannerTopSpacing)
            }

            if viewModel.isAwaitingFunds {
                PolymarketOrderNotificationsView(notifications: [.awaitingFunds])
                    .padding(.horizontal, PolymarketMainLayout.horizontalPadding)
                    .padding(.top, Constants.bannerTopSpacing)
            }

            PolymarketPositionsBlockView(viewModel: viewModel.positionsViewModel)

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
        .padding(.horizontal, PolymarketMainLayout.horizontalPadding)
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
            .padding(.horizontal, PolymarketMainLayout.horizontalPadding)
    }

    // MARK: - List

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: Constants.contentSpacing) {
                header

                PolymarketEventsTabsView(viewModel: viewModel.eventsViewModel)
                    .readGeometry(inCoordinateSpace: .named(Constants.scrollSpace)) { viewModel.handleViewAction(.onTabsMove(minY: $0.frame.minY, navBarHeight: navBarHeight)) }
                    .opacity(viewModel.isTabsPinned ? 0 : 1)
                    .allowsHitTesting(!viewModel.isTabsPinned)

                PolymarketEventsListView(viewModel: viewModel.eventsViewModel)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: navBarHeight)
        }
        .coordinateSpace(name: Constants.scrollSpace)
        .refreshable { await viewModel.refresh() }
    }
}

extension PolymarketMainView {
    enum Constants {
        static let scrollSpace = "PolymarketMainScroll"

        static let contentSpacing: CGFloat = 12
        static let navBarTopPadding: CGFloat = 8
        static let navBarSettingsHeight: CGFloat = 56

        static let headerTopPadding: CGFloat = 56
        static let headerSpacing: CGFloat = 40
        static let bannerTopSpacing: CGFloat = 24
        static let bannerIconSide: CGFloat = 20
    }
}
