//
//  FeedTabsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct FeedTabsView: View {
    @ObservedObject var viewModel: FeedTabsViewModel
    @ObservedObject var shtorkaStateObject: MainShtorkaStateObject

    let onSwitchTab: () -> Void

    var body: some View {
        LazyVStack(spacing: Constants.sectionSpacing, pinnedViews: [.sectionHeaders]) {
            Section {
                tabContent
                    .padding(.top, Constants.tabContentTopInset)
                    .padding(.bottom, Constants.tabContentBottomInset)
            } header: {
                if viewModel.tabs.count > 1 {
                    tabChips
                        .padding(.bottom, Constants.chipsBottomInset)
                        .background(pinnedChipsBackground)
                        .readGeometry(\.size.height) { shtorkaStateObject.report(tabChips: $0) }
                }
            }
        }
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

    private var tabChips: some View {
        TabNavigation(data: viewModel.tabs, selection: tabSelection)
            .variant(.material)
            .scrollable()
    }

    private var pinnedChipsBackground: Color {
        shtorkaStateObject.size == .full ? DesignSystem.Color.bgPrimary : .clear
    }

    private var tabSelection: Binding<FeedTab> {
        Binding(
            get: { viewModel.selectedTab },
            set: { tab in
                let isSwitchingTab = tab.id != viewModel.selectedTab.id

                viewModel.onSelectTab(tab)
                shtorkaStateObject.expand()

                if isSwitchingTab {
                    onSwitchTab()
                }
            }
        )
    }
}

// MARK: - Constants

private extension FeedTabsView {
    enum Constants {
        static let sectionSpacing: CGFloat = 20
        static let tabContentTopInset: CGFloat = 4
        static let tabContentBottomInset: CGFloat = 20
        static let chipsBottomInset: CGFloat = 8
    }
}
