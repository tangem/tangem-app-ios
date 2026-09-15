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

    @Binding var areChipsPinned: Bool
    let onTabChange: (String) -> Void
    let onChipsHeightChange: (CGFloat) -> Void

    @State private var chipsHeight: CGFloat = 0

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                tabContent
                    .id(viewModel.selectedTab.id)
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
                }
            }
        }
        .onAppear { onTabChange(viewModel.selectedTab.id) }
        .onChange(of: viewModel.selectedTab.id, perform: onTabChange)
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
    private var tabContent: some View {
        switch viewModel.selectedTab {
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
            set: { tab in
                viewModel.onSelectTab(tab)
                shtorkaActions.expand()
            }
        )
    }
}

// MARK: - Constants

private extension FeedTabsView {
    enum Constants {
        static let tabContentBottomInset: CGFloat = 20
        static let fadeHeight: CGFloat = 96
        static let fadeBottomOverlap: CGFloat = 9
    }
}
