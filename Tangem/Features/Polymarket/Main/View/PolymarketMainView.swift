//
//  PolymarketMainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
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

            if viewModel.isSearching {
                DesignSystem.Color.bgPrimary
                    .ignoresSafeArea()

                PolymarketSearchView(viewModel: viewModel.search)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { searchField }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .bindAlert($viewModel.alert)
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

    // MARK: - Search

    private var searchField: some View {
        Search(
            text: $viewModel.searchQuery,
            isActive: $viewModel.isSearchFieldActive,
            clearAction: { viewModel.searchQuery = "" },
            cancelAction: viewModel.exitSearch
        )
        .placeholder(Localization.commonSearch)
        .submitLabel(.search)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.searchFieldVerticalPadding)
        .background(alignment: .bottom) {
            Fade(position: .bottom)
                .variant(.hard)
                .blurred()
                .padding(.top, -Constants.searchFadeOverhang)
                // With the keyboard up there is nothing below to fill, and stretching would drag the
                // scrim's opaque end under the keyboard, leaving the field on the transparent part.
                .ignoresSafeArea(edges: viewModel.isSearchFieldActive ? [] : .bottom)
        }
    }

    // MARK: - Navbar

    private var navigationBar: some View {
        NavigationBar(
            settings: .init(backgroundColor: .clear, horizontalPadding: Constants.horizontalPadding, height: Constants.navBarSettingsHeight),
            titleView: { titleView },
            leftButtons: { NavigationBarButton.back { viewModel.dismiss() } },
            rightButtons: {
                PolymarketOverflowMenu(
                    onHowItWorks: viewModel.openHowItWorks,
                    onSupportChat: viewModel.openSupportChat
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
            balanceBlock

            if viewModel.isRegionRestricted {
                regionRestrictionBanner
                    .padding(.top, Constants.bannerTopSpacing)
            }

            if viewModel.isAwaitingFunds {
                PolymarketOrderNotificationsView(notifications: [.awaitingFunds])
                    .padding(.horizontal, Constants.horizontalPadding)
                    .padding(.top, Constants.bannerTopSpacing)
            }

            positionsSection
                .padding(.top, Constants.positionsTopSpacing)

            exploreEventsTitle
                .padding(.top, Constants.headerSpacing)
        }
        .padding(.top, Constants.headerTopPadding)
    }

    // MARK: - My Predictions

    @ViewBuilder
    private var positionsSection: some View {
        switch viewModel.positionsState {
        case .loading where viewModel.hadPositionsBefore || viewModel.isRetryingPositions:
            positionsBlock {
                PolymarketPositionsSkeletonView(rowCount: Constants.positionsSkeletonRowCount)
            }
        case .loading:
            EmptyView()
        case .failed:
            positionsBlock {
                PolymarketEmptyMessageView(
                    message: Localization.predictionPositionsLoadError,
                    onRetry: { viewModel.loadPositions(userInitiated: true) }
                )
            }
        case .loaded(let models) where !models.isEmpty:
            positionsBlock {
                VStack(spacing: Constants.positionsRowSpacing) {
                    ForEach(models) { model in
                        PolymarketPositionRow(model: model) { viewModel.openPosition(id: model.id) }
                    }

                    if viewModel.hasMorePositions {
                        seeAllPositionsButton
                    }
                }
            }
        case .loaded where viewModel.hadPositionsBefore:
            positionsBlock {
                VStack(spacing: Constants.positionsRowSpacing) {
                    PolymarketNoActivePositionsView()

                    if viewModel.hasMorePositions {
                        seeAllPositionsButton
                    }
                }
            }
        case .loaded:
            EmptyView()
        }
    }

    private func positionsBlock(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: Constants.positionsSpacing) {
            positionsHeader

            content()
        }
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private var positionsHeader: some View {
        HStack(spacing: Constants.positionsSpacing) {
            Text(Localization.predictionPositionsMainTitle)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            finishedPositionsButton
        }
    }

    /// The badge is taller than the title, so it holds its place instead of pushing the list down when it arrives.
    private var finishedPositionsButton: some View {
        SwiftUI.Button { viewModel.openMyPositions(tab: .finished) } label: {
            Badge(label: Localization.predictionPositionsFinished, accessibilityLabel: nil)
                .size(.x9)
                .slotEnd(DesignSystem.Icons.ChevronRight.regular16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.predictionPositionsFinished)
        .visible(viewModel.hasFinishedPositions)
        .allowsHitTesting(viewModel.hasFinishedPositions)
        .accessibilityHidden(!viewModel.hasFinishedPositions)
    }

    private var seeAllPositionsButton: some View {
        TangemUI.Button(
            label: Localization.predictionPositionsViewAllActive,
            accessibilityLabel: nil,
            action: { viewModel.openMyPositions(tab: .active) }
        )
        .size(.x9)
        .styleType(.secondary(.default))
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

    @ViewBuilder
    private var balanceBlock: some View {
        if isBalanceLoading {
            balanceBlockSkeleton
        } else {
            VStack(spacing: Constants.balanceSpacing) {
                balanceSelector

                balanceAmount

                actionButtons
                    .padding(.top, Constants.actionButtonsTopPadding)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Constants.actionButtonsBottomPadding)
        }
    }

    private var isBalanceLoading: Bool {
        if case .loading(.none) = viewModel.balance {
            return true
        }

        return false
    }

    private var balanceBlockSkeleton: some View {
        VStack(spacing: Constants.balanceSpacing) {
            skeleton(width: Constants.skeletonSelectorWidth, height: Constants.skeletonSelectorHeight)

            skeleton(
                width: Constants.skeletonAmountWidth,
                height: Constants.skeletonAmountHeight,
                cornerRadius: Constants.skeletonAmountHeight / 2
            )
            .padding(.vertical, Constants.balanceSpacing)

            HStack(spacing: Constants.actionButtonsSpacing) {
                ForEach(0 ..< Constants.skeletonActionCount, id: \.self) { _ in
                    VStack(spacing: Constants.skeletonActionSpacing) {
                        skeleton(
                            width: TangemMainActionButton.Size.buttonSide,
                            height: TangemMainActionButton.Size.buttonSide,
                            cornerRadius: TangemMainActionButton.Size.buttonSide / 2
                        )

                        skeleton(width: Constants.skeletonActionTitleWidth, height: Constants.skeletonSelectorHeight)
                    }
                    .frame(minWidth: Constants.actionWidth)
                }
            }
            .padding(.top, Constants.actionButtonsTopPadding)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Constants.actionButtonsBottomPadding)
    }

    private func skeleton(width: CGFloat, height: CGFloat, cornerRadius: CGFloat? = nil) -> some View {
        Shimmer()
            .frame(width: width, height: height)
            .clipShape(.rect(cornerRadius: cornerRadius ?? height / 2, style: .continuous))
    }

    private var balanceAmount: some View {
        LoadableBalanceView(
            state: viewModel.balance,
            style: .init(font: DesignSystem.Font.displayMediumToken, textColor: DesignSystem.Color.textPrimary),
            loader: .init(size: Constants.balanceLoaderSize)
        )
        .padding(.trailing, Constants.balanceAmountTrailingPadding)
        .id(viewModel.balanceMode)
        .transition(.opacity)
    }

    private var balanceSelector: some View {
        SwiftUI.Button {
            withAnimation(.easeInOut(duration: Constants.balanceModeAnimationDuration)) {
                viewModel.onBalanceModeTap()
            }
        } label: {
            HStack(spacing: Constants.balanceSelectorSpacing) {
                Text(viewModel.balanceMode == .total
                    ? Localization.predictionMainTotalBalance
                    : Localization.predictionMainAvailableBalance)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .id(viewModel.balanceMode)
                    .transition(.opacity)

                DesignSystem.Icons.ChevronDoubleVertical.regular16.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: Constants.selectorIconSize))
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSwitchBalanceMode)
    }

    private var actionButtons: some View {
        HStack(spacing: Constants.actionButtonsSpacing) {
            TangemMainActionButton(
                title: Localization.commonAddFunds,
                icon: Assets.DesignSystem.arrowDown,
                action: viewModel.onAddFundsTap,
                reasonTapWhenDisabled: viewModel.onAddFundsTap
            )
            .frame(minWidth: Constants.actionWidth)
            .disabled(viewModel.addFundsState != .available)
            .accessibilityIdentifier(PolymarketAccessibilityIdentifiers.addFundsButton)

            TangemMainActionButton(
                title: Localization.predictionMainWithdraw,
                icon: Assets.DesignSystem.arrowUp,
                action: viewModel.onWithdrawTap,
                reasonTapWhenDisabled: viewModel.onWithdrawTap
            )
            .frame(minWidth: Constants.actionWidth)
            .disabled(!viewModel.withdrawState.isAvailable)
            .accessibilityIdentifier(PolymarketAccessibilityIdentifiers.withdrawButton)
        }
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
                    .readGeometry(inCoordinateSpace: .named(Constants.scrollSpace)) { viewModel.updatePinnedState(tabsMinY: $0.frame.minY, navBarHeight: navBarHeight) }
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
                .onTapGesture { viewModel.openEventDetails(eventID: model.id) }
                .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    private var failedState: some View {
        PolymarketEmptyMessageView(message: Localization.predictionMainEventsLoadError, onRetry: viewModel.retry)
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
        static let searchFieldVerticalPadding: CGFloat = 12
        static let searchFadeOverhang: CGFloat = 16
        static let navBarTopPadding: CGFloat = 8
        static let navBarSettingsHeight: CGFloat = 56
        static let tabsVerticalPadding: CGFloat = 8
        static let paginationVerticalPadding: CGFloat = 20

        static let positionsSpacing: CGFloat = 16
        static let positionsRowSpacing: CGFloat = 8
        static let positionsTopSpacing: CGFloat = 52
        static let positionsSkeletonRowCount = 3
        static let headerTopPadding: CGFloat = 56
        static let headerSpacing: CGFloat = 40
        static let bannerTopSpacing: CGFloat = 24
        static let bannerIconSide: CGFloat = 20
        static let balanceSpacing: CGFloat = 4
        static let balanceAmountTrailingPadding: CGFloat = 4
        static let balanceLoaderSize = CGSize(width: 160, height: 40)

        static let skeletonSelectorWidth: CGFloat = 150
        static let skeletonSelectorHeight: CGFloat = 12
        static let skeletonAmountWidth: CGFloat = 170
        static let skeletonAmountHeight: CGFloat = 44
        static let skeletonActionCount = 2
        static let skeletonActionSpacing: CGFloat = 8
        static let skeletonActionTitleWidth: CGFloat = 64
        static let balanceSelectorSpacing: CGFloat = 4
        static let selectorIconSize: CGFloat = 16
        static let balanceModeAnimationDuration: TimeInterval = 0.2
        static let actionButtonsSpacing: CGFloat = 0
        static let actionButtonsTopPadding: CGFloat = 28
        static let actionButtonsBottomPadding: CGFloat = 24
        static let actionWidth: CGFloat = 102

        static let eventsPlaceholderMinHeight: CGFloat = 320
    }
}
