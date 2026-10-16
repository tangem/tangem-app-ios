//
//  CollectiblesMainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct CollectiblesMainView: View {
    @ObservedObject var viewModel: CollectiblesMainViewModel

    let actionsMenuViewModel: CollectiblesActionsMenuViewModel
    let dismissStyle: CollectiblesDismissStyle
    let onDismiss: () -> Void

    @State private var scrollHeight: CGFloat = 0
    @State private var topInset: CGFloat = 0
    @State private var tabsHeaderHeight: CGFloat = 0
    @State private var accountHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            catalogueScroll
                .opacity(viewModel.isSearching ? 0 : 1)
                .accessibilityHidden(viewModel.isSearching)

            if viewModel.isSearching {
                searchOverlay
                    .transition(searchOverlayTransition)
            }
        }
        .animation(.default, value: viewModel.isSearching)
        .infinityFrame()
        .readGeometry(\.safeAreaInsets.top, bindTo: $topInset)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.showsSearchBar {
                searchBar
                    .transition(.opacity)
            }
        }
        .animation(.default, value: viewModel.showsSearchBar)
        // [REDACTED_TODO_COMMENT]
        .collectiblesDevnetProgress(actionsMenuViewModel.devnet)
        .task(viewModel.observe)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar { toolbarContent }
    }
}

private extension CollectiblesMainView {
    // MARK: - Toolbar

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        dismissStyle.toolbarButton(placement: .topBarLeading, action: onDismiss)

        ToolbarItem(placement: .principal) {
            navigationBarTitle
        }

        ToolbarItem(placement: .topBarTrailing) {
            ActionsMenu(viewModel: actionsMenuViewModel)
        }
    }

    // MARK: - View properties

    var navigationBarTitle: some View {
        VStack(spacing: 2) {
            Text(Localization.collectiblesMainTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            if viewModel.showsBalanceInNavigationBar {
                Text(viewModel.accountBalanceText)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
        .animation(.default, value: viewModel.showsBalanceInNavigationBar)
    }

    var catalogueScroll: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                catalogue
                    .padding(.bottom, Metrics.contentBottomPadding)
                    .background(alignment: .top) {
                        Color.clear
                            .frame(height: Metrics.scrollAnchorHeight)
                            .id(Constants.scrollAnchor)
                    }
                    .readGeometry(\.frame.minY, inCoordinateSpace: .named(Constants.scrollSpace)) {
                        viewModel.updateScrollOffset(contentMinY: $0)
                    }
            }
            .refreshable { await viewModel.refresh() }
            .coordinateSpace(name: Constants.scrollSpace)
            .readGeometry(\.size.height, bindTo: $scrollHeight)
            .onChange(of: viewModel.selectedLoreID) { _ in
                landOnPinnedTabs(proxy)
            }
        }
    }

    var searchOverlay: some View {
        ScrollView(showsIndicators: false) {
            CollectiblesPacksView(viewModel: viewModel.searchResultsViewModel)
                .padding(.top, Metrics.searchResultsTopPadding)
                .padding(.bottom, Metrics.contentBottomPadding)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.automatic)
        // Reaches under the bar like the catalogue does, so the blur has content instead of a seam.
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    var catalogue: some View {
        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
            CollectiblesAccountView(
                viewModel: viewModel.accountViewModel,
                balanceCoordinateSpace: .named(Constants.scrollSpace),
                onBalanceMaxYChange: { viewModel.updateBalanceVisibility(balanceMaxY: $0) }
            )
            .readGeometry(\.size.height, bindTo: $accountHeight)

            // Closes the gap to the tabs without touching the header itself, so its height never changes.
            Spacer(minLength: Metrics.tabsTopPadding - Metrics.pinnedTabsTopPadding)
                .fixedSize()

            Section {
                // A screen's worth at minimum: a short lore must not shrink the page and unpin the tabs.
                CollectiblesPacksView(viewModel: viewModel.packsViewModel)
                    .padding(.top, Metrics.gridTopPadding)
                    .frame(minHeight: gridMinHeight, alignment: .top)
            } header: {
                tabs
            }
        }
    }

    /// One instance, relocated by the pinning rather than duplicated: a second row would lose its horizontal offset.
    var tabs: some View {
        CollectiblesLoreTabsView(viewModel: viewModel.loreTabsViewModel)
            .padding(.top, Metrics.pinnedTabsTopPadding)
            .padding(.bottom, Metrics.pinnedTabsBottomPadding)
            .background {
                if viewModel.isTabsPinned {
                    Fade(position: .top)
                        .backgroundColor(DesignSystem.Color.bgPrimary)
                        .padding(.top, -topInset)
                }
            }
            .readGeometry(inCoordinateSpace: .named(Constants.scrollSpace)) {
                viewModel.updatePinnedState(tabsMinY: $0.frame.minY)
                tabsHeaderHeight = $0.frame.height
            }
            // The pinned header must never animate its own position, or reappearing tabs drop in from above.
            .transaction { $0.animation = nil }
    }

    var searchBar: some View {
        HStack(spacing: Metrics.searchCloseButtonSpacing) {
            Search(
                text: $viewModel.searchQuery,
                isActive: $viewModel.isSearchFieldFocused,
                clearAction: { viewModel.searchQuery = "" }
            )
            .placeholder(Localization.commonSearch)
            .showsCloseButton(false)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .keyboardType(.alphabet)

            if viewModel.isSearching {
                searchCloseButton
                    .transition(.opacity)
            }
        }
        .animation(Metrics.searchCloseButtonAnimation, value: viewModel.isSearching)
        .padding(.horizontal, Metrics.searchHorizontalPadding)
        .padding(.vertical, searchBarVerticalPadding)
        .background(alignment: .bottom) {
            Fade(position: .bottom)
                .variant(searchFadeVariant)
                .blurred()
                .padding(.top, -Metrics.searchFadeOverhang)
                // With the keyboard up there is nothing below to fill, and stretching would drag the
                // scrim's opaque end under the keyboard, leaving the field on the transparent part.
                .ignoresSafeArea(edges: viewModel.isSearchFieldFocused ? [] : .bottom)
        }
    }

    var searchCloseButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonCancel,
            action: viewModel.exitSearch
        )
        .styleType(.material(.glass))
        .size(.x11)
    }
}

// MARK: - Actions

private extension CollectiblesMainView {
    func landOnPinnedTabs(_ proxy: ScrollViewProxy) {
        let pinnedTabsOffset = accountHeight + Metrics.tabsTopPadding - Metrics.pinnedTabsTopPadding
        let travel = scrollHeight - Metrics.scrollAnchorHeight

        guard viewModel.scrollOffset > pinnedTabsOffset, travel > 0 else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            proxy.scrollTo(Constants.scrollAnchor, anchor: UnitPoint(x: 0, y: -pinnedTabsOffset / travel))
        }
    }
}

// MARK: - Calculations

private extension CollectiblesMainView {
    /// Removal pins its own curves: an inherited slow-start keyboard transaction reads as a hang before the drop.
    var searchOverlayTransition: AnyTransition {
        .asymmetric(
            insertion: .offset(y: Metrics.searchOverlayTravel).combined(with: .opacity),
            removal: .move(edge: .bottom).animation(.easeOut(duration: Metrics.searchOverlayDismissDuration))
                .combined(with: .opacity.animation(.easeOut(duration: Metrics.searchOverlayDismissFadeDuration)))
        )
    }

    /// Sized so the scroll clamp itself lands a switched lore with the tabs pinned and the first card
    /// `tabsToGridGap` below them.
    var gridMinHeight: CGFloat {
        let landingCorrection = Metrics.gridTopPadding + Metrics.pinnedTabsBottomPadding - Metrics.tabsToGridGap
        return max(scrollHeight - tabsHeaderHeight - Metrics.contentBottomPadding + landingCorrection, 0)
    }

    /// Design pads tighter with the keyboard down, where the home indicator already adds space below.
    var searchBarVerticalPadding: CGFloat {
        viewModel.isSearchFieldFocused ? Metrics.searchVerticalPaddingWithKeyboard : Metrics.searchVerticalPadding
    }

    /// Design switches the scrim from 60% to 95% while the keyboard is up.
    var searchFadeVariant: Fade.Variant {
        viewModel.isSearchFieldFocused ? .hard : .soft
    }
}

// MARK: - Metrics

private extension CollectiblesMainView {
    enum Metrics {
        static let tabsTopPadding: CGFloat = 40
        static let pinnedTabsTopPadding: CGFloat = 8
        static let pinnedTabsBottomPadding: CGFloat = 8
        /// From the ask: 20pt between the pinned tabs row and the first card after a lore switch.
        static let tabsToGridGap: CGFloat = 20
        static let gridTopPadding: CGFloat = 16
        /// From the mockup: the toolbar row ends at 106 and the first card starts at 134.
        static let searchResultsTopPadding: CGFloat = 28
        static let contentBottomPadding: CGFloat = 24
        static let searchOverlayTravel: CGFloat = 40
        static let searchOverlayDismissDuration: TimeInterval = 0.36
        static let searchOverlayDismissFadeDuration: TimeInterval = 0.28

        static let scrollAnchorHeight: CGFloat = 1
        static let searchHorizontalPadding: CGFloat = 16
        static let searchCloseButtonSpacing: CGFloat = 8
        static let searchCloseButtonAnimation: Animation = .timingCurve(0.8, 0, 0.2, 1, duration: 0.3)
        static let searchVerticalPadding: CGFloat = 8
        static let searchVerticalPaddingWithKeyboard: CGFloat = 12
        static let searchFadeOverhang: CGFloat = 16
    }

    enum Constants {
        static let scrollSpace = "collectibles_main_scroll"
        static let scrollAnchor = "collectibles_main_scroll_anchor"
    }
}

// MARK: - Previews

private struct PreviewCatalogueProvider: CollectiblesLoresProvider, CollectiblesPacksProvider {
    func load() async throws -> CollectiblesLoreCatalogue {
        CollectiblesLoreCatalogue(
            lores: [
                CollectiblesLore(id: "pokemon", title: "Pokemon", packsCount: 7),
                CollectiblesLore(id: "sports", title: "Sports", packsCount: 5),
            ],
            totalPacksCount: 12
        )
    }

    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        let packs = (1 ... 6).map { index in
            CollectiblesPack(
                id: "pack-\(index)",
                loreID: "pokemon",
                currencyCode: "USD",
                machine: CollectiblesMachine(
                    name: "Elite \(index)",
                    artworkURL: nil,
                    price: Decimal(50 * index),
                    platformFee: 1,
                    cardsPerPack: 1,
                    buybackRate: 0.85,
                    expectedValue: Decimal(55 * index),
                    tiers: []
                )
            )
        }
        return CollectiblesPacksPage(packs: packs, hasNext: false, cursor: nil)
    }
}

#Preview {
    NavigationStack {
        CollectiblesMainView(
            viewModel: CollectiblesMainViewModel(routable: nil, accountModel: nil, catalogueProvider: PreviewCatalogueProvider()),
            actionsMenuViewModel: CollectiblesActionsMenuViewModel(routable: nil),
            dismissStyle: .back,
            onDismiss: {}
        )
    }
}
