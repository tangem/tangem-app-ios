//
//  GachaMainView.swift
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

struct GachaMainView: View {
    @ObservedObject var viewModel: GachaMainViewModel

    let onBack: () -> Void

    @State private var scrollHeight: CGFloat = 0
    @State private var topInset: CGFloat = 0
    @State private var tabsHeaderHeight: CGFloat = 0

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
        .task(viewModel.observe)
        // [REDACTED_TODO_COMMENT]
        .topNavigation(
            title: "Packs account",
            subtitle: viewModel.showsBalanceInNavigationBar ? viewModel.accountBalanceText : nil,
            leading: .custom(.back(action: onBack))
        )
    }
}

private extension GachaMainView {
    // MARK: - View properties

    var catalogueScroll: some View {
        ScrollView(showsIndicators: false) {
            catalogue
                .padding(.bottom, Metrics.contentBottomPadding)
        }
        .coordinateSpace(name: Constants.scrollSpace)
        .readGeometry(\.size.height, bindTo: $scrollHeight)
    }

    var searchOverlay: some View {
        ScrollView(showsIndicators: false) {
            GachaPacksView(viewModel: viewModel.searchResultsViewModel)
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
            GachaAccountView(viewModel: viewModel.accountViewModel)

            // Closes the gap to the tabs without touching the header itself, so its height never changes.
            Spacer(minLength: Metrics.tabsTopPadding - Metrics.pinnedTabsTopPadding)
                .fixedSize()

            Section {
                // A screen's worth at minimum: a short lore must not shrink the page and unpin the tabs.
                GachaPacksView(viewModel: viewModel.packsViewModel)
                    .padding(.top, Metrics.gridTopPadding)
                    .frame(minHeight: gridMinHeight, alignment: .top)
            } header: {
                tabs
            }
        }
    }

    /// One instance, relocated by the pinning rather than duplicated: a second row would lose its horizontal offset.
    var tabs: some View {
        GachaLoreTabsView(viewModel: viewModel.loreTabsViewModel)
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
        Search(
            text: $viewModel.searchQuery,
            isActive: $viewModel.isSearchFieldFocused,
            clearAction: { viewModel.searchQuery = "" },
            cancelAction: viewModel.exitSearch
        )
        .placeholder(Localization.commonSearch)
        .submitLabel(.search)
        .autocorrectionDisabled()
        .keyboardType(.alphabet)
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
}

// MARK: - Calculations

private extension GachaMainView {
    /// Removal pins its own curves: an inherited slow-start keyboard transaction reads as a hang before the drop.
    var searchOverlayTransition: AnyTransition {
        .asymmetric(
            insertion: .offset(y: Metrics.searchOverlayTravel).combined(with: .opacity),
            removal: .move(edge: .bottom).animation(.easeOut(duration: Metrics.searchOverlayDismissDuration))
                .combined(with: .opacity.animation(.easeOut(duration: Metrics.searchOverlayDismissFadeDuration)))
        )
    }

    /// Sized so the scroll clamp itself lands a switched lore with the tabs pinned and the first card
    /// `tabsToGridGap` below them, with no scroll command to misfire.
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

private extension GachaMainView {
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
        static let searchOverlayDismissDuration: TimeInterval = 0.3
        static let searchOverlayDismissFadeDuration: TimeInterval = 0.2

        static let searchHorizontalPadding: CGFloat = 16
        static let searchVerticalPadding: CGFloat = 8
        static let searchVerticalPaddingWithKeyboard: CGFloat = 12
        static let searchFadeOverhang: CGFloat = 16
    }

    enum Constants {
        static let scrollSpace = "gacha_main_scroll"
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        GachaMainView(viewModel: GachaMainViewModel(), onBack: {})
    }
}
