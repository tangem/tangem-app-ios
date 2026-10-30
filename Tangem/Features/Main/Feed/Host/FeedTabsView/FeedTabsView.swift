//
//  FeedTabsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct FeedTabsView: View {
    @ObservedObject var viewModel: FeedTabsViewModel
    let container: any FeedContainer

    @Binding var areChipsPinned: Bool
    let scrollProxy: ScrollViewProxy
    let viewportHeight: CGFloat
    let scrollTarget: (_ tabID: String, _ pinTabs: Bool, _ chipsPinned: Bool) -> FeedScrollTarget?
    let onChipsHeightChange: (CGFloat) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mainShtorkaSize) private var sheetSize

    @State private var chipsHeight: CGFloat = 0
    @State private var pendingTab: FeedTab?

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                FeedTabPagerView(
                    pager: viewModel.pager,
                    selection: viewModel.selectedTab,
                    onPageChange: { move(to: viewModel.resolve(scrollTarget(for: $0, pinTabs: false))) },
                    onSettle: viewModel.pagesDidSettle
                ) { page in
                    tabContent(for: page.tab)
                        .padding(.top, page.topInset)
                }
                .clipped()
                .reverseMask(alignment: .top) {
                    if areChipsPinned {
                        pinnedTabsFade
                    }
                }
                .padding(.bottom, Constants.tabContentBottomInset)
            } header: {
                if viewModel.tabs.count > 1 {
                    tabChips
                        .padding(.bottom, FeedConstants.chipsBottomInset)
                        .onGeometryChange(for: Bool.self, of: {
                            $0.frame(in: .named(FeedConstants.scrollCoordinateSpace)).minY <= 0.5
                        }) { areChipsPinned = $0 }
                        // On iOS 16, interactive rows can otherwise receive taps through the pinned header.
                        .zIndex(1)
                }
            }
        }
        .background(alignment: .top) {
            Color.clear
                .frame(height: FeedConstants.scrollAnchorHeight)
                .id(FeedConstants.tabsAnchorID)
        }
        .onAppear { move(to: scrollTarget(for: viewModel.selectedTab, pinTabs: false)) }
        .onReceive(viewModel.tabSelectionPublisher, perform: expandAndSelect)
        .onChange(of: viewportHeight) { _ in
            guard sheetSize == .full, let pendingTab else { return }

            self.pendingTab = nil
            select(pendingTab)
        }
        .onChange(of: sheetSize) { size in
            if size != .full {
                pendingTab = nil
            }
        }
        .overlay(alignment: .top) { chipsMeasurer }
    }

    private var pinnedTabsFade: some View {
        GeometryReader { geometry in
            FeedTopFade(
                height: Constants.fadeHeight,
                visibleHeight: FeedConstants.searchContentInset + chipsHeight + Constants.fadeBottomOverlap
            )
            .offset(y: -geometry.frame(in: .named(FeedConstants.scrollCoordinateSpace)).minY - FeedConstants.searchContentInset)
        }
    }

    @ViewBuilder
    private func tabContent(for tab: FeedTab) -> some View {
        switch tab {
        case .crypto(let viewModel):
            CryptoFeedView(viewModel: viewModel)
        case .realAssets(let viewModel):
            RealAssetsFeedView(viewModel: viewModel)
        case .earn(let viewModel):
            EarnFeedView(viewModel: viewModel)
        case .predictions:
            PredictionsFeedView()
        }
    }

    /// The lazy pinned header stays unmeasured while collapsed, yet the medium detent needs the chips height before that.
    @ViewBuilder
    private var chipsMeasurer: some View {
        if viewModel.tabs.count > 1 {
            tabChips
                .fixedSize(horizontal: false, vertical: true)
                .hidden()
                .readGeometry(\.size.height) { height in
                    chipsHeight = height
                    onChipsHeightChange(height)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var tabChips: some View {
        TabNavigation(data: viewModel.tabs, selection: tabSelection)
            .variant(.material)
            .scrollable()
            .hapticFeedback()
    }

    private var tabSelection: Binding<FeedTab> {
        Binding(
            get: { viewModel.selectedTab },
            set: expandAndSelect
        )
    }

    // MARK: - Switching

    private func expandAndSelect(_ tab: FeedTab) {
        if sheetSize.isNonFullFeedSheet || pendingTab != nil {
            pendingTab = tab
            container.expand()
            return
        }

        select(tab)
    }

    private func select(_ tab: FeedTab) {
        viewModel.onSelectTab(tab)
    }

    private func scrollTarget(for tab: FeedTab, pinTabs: Bool) -> FeedScrollTarget? {
        scrollTarget(tab.id, pinTabs, areChipsPinned)
    }

    private func move(to target: FeedScrollTarget?) {
        switch target {
        case .pinTabs:
            withAnimation(reduceMotion ? nil : .easeInOut(duration: Constants.pinDuration)) {
                scrollProxy.scrollTo(FeedConstants.tabsAnchorID, anchor: .top)
            }
        case .jump(let anchor, _):
            scrollProxy.scrollTo(FeedConstants.contentAnchorID, anchor: anchor)
        case .scroll(let anchor):
            withAnimation(reduceMotion ? nil : .easeInOut(duration: Constants.pinDuration)) {
                scrollProxy.scrollTo(FeedConstants.contentAnchorID, anchor: anchor)
            }
        case nil:
            break
        }
    }
}

// MARK: - Constants

private extension FeedTabsView {
    enum Constants {
        static let tabContentBottomInset: CGFloat = 20
        static let fadeHeight: CGFloat = 96
        static let fadeBottomOverlap: CGFloat = 9
        static let pinDuration: TimeInterval = 0.3
    }
}
