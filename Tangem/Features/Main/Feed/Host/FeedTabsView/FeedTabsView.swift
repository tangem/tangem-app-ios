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
    let shtorkaActions: any MainShtorkaViewActionProvider
    let shtorkaReporting: any MainShtorkaReporting

    @Binding var areChipsPinned: Bool
    let scrollProxy: ScrollViewProxy
    let viewportHeight: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.mainShtorkaSize) private var sheetSize

    @State private var chipsHeight: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var slideGeneration = 0
    @State private var pendingTab: FeedTab?

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                ZStack(alignment: .top) {
                    ForEach(viewModel.pages) { page in
                        tabContent(for: page.tab)
                            .padding(.top, page.topInset)
                            .clipped()
                            .lockedGeometry()
                            .offset(x: page.offset * slideWidth)
                    }
                }
                .onGeometryChange(for: CGFloat.self, of: \.size.width) { contentWidth = $0 }
                .padding(.bottom, Constants.tabContentBottomInset)
            } header: {
                if viewModel.tabs.count > 1 {
                    tabChips
                        .padding(.bottom, FeedConstants.chipsBottomInset)
                        .background(alignment: .top) {
                            if areChipsPinned {
                                pinnedTabsFade
                            }
                        }
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
        .onChange(of: viewModel.selectedTab.id) { _ in show(viewModel.selectedTab) }
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
        // The search bar clips the upper part of Figma's 121 pt fade; its 40 pt ramp ends 9 pt below the chips.
        Fade(position: .top)
            .variant(.hard)
            .frame(height: Constants.fadeHeight)
            .frame(height: FeedConstants.searchContentInset + chipsHeight + Constants.fadeBottomOverlap, alignment: .bottom)
            .clipped()
            .offset(y: -FeedConstants.searchContentInset)
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
                    shtorkaReporting.report(tabChips: height)
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
        if sheetSize != .full || pendingTab != nil {
            pendingTab = tab
            shtorkaActions.expand()
            return
        }

        select(tab)
    }

    private func select(_ tab: FeedTab) {
        let isAlreadySelected = tab.id == viewModel.selectedTab.id
        viewModel.onSelectTab(tab)
        if isAlreadySelected {
            move(to: viewModel.startSlide(to: tab, target: scrollTarget(for: tab, pinTabs: true)))
        }
    }

    private var slideWidth: CGFloat {
        layoutDirection == .leftToRight ? contentWidth : -contentWidth
    }

    private func show(_ tab: FeedTab) {
        let target = scrollTarget(for: tab, pinTabs: true)

        guard #available(iOS 17.0, *), !reduceMotion else {
            move(to: viewModel.showInstantly(tab, target: target))
            return
        }

        move(to: viewModel.startSlide(to: tab, target: target))
        slideGeneration += 1
        let generation = slideGeneration

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Constants.slideDelay))
            guard generation == slideGeneration else { return }

            withAnimation(Constants.slideAnimation) {
                viewModel.slide()
            } completion: {
                guard generation == slideGeneration else { return }

                move(to: viewModel.settleSlide())
            }
        }
    }

    private func scrollTarget(for tab: FeedTab, pinTabs: Bool) -> FeedScrollTarget? {
        shtorkaReporting.scrollTarget(
            forTab: tab.id,
            viewportHeight: viewportHeight,
            pinTabs: pinTabs,
            chipsPinned: areChipsPinned
        )
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
        static let slideDelay = 50
        static let slideAnimation: Animation = .interpolatingSpring(mass: 1, stiffness: 400, damping: 40)
    }
}

// MARK: - Geometry

private extension View {
    @ViewBuilder
    func lockedGeometry() -> some View {
        if #available(iOS 17.0, *) {
            geometryGroup()
        } else {
            self
        }
    }
}
